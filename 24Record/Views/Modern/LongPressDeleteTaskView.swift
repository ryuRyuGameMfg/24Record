import SwiftUI

struct LongPressDeleteTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    let onDragStart: ((SDTimeBlock) -> Void)?
    let onDragEnd: (() -> Void)?
    let onDragMove: ((CGPoint) -> Void)?
    @Binding var isAnyTaskFloating: Bool
    
    init(block: SDTimeBlock, viewModel: SwiftDataTimeTrackingViewModel, onDragStart: ((SDTimeBlock) -> Void)? = nil, onDragEnd: (() -> Void)? = nil, onDragMove: ((CGPoint) -> Void)? = nil, isAnyTaskFloating: Binding<Bool> = .constant(false)) {
        self.block = block
        self.viewModel = viewModel
        self.onDragStart = onDragStart
        self.onDragEnd = onDragEnd
        self.onDragMove = onDragMove
        self._isAnyTaskFloating = isAnyTaskFloating
    }
    
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingActions = false
    @State private var isDraggingToMove = false
    @State private var dragStartTime: Date?
    @State private var dragPreviewTime: Date?
    
    // Drag & Drop states
    @State private var dropZones: [DropZone] = []
    @State private var nearestDropZone: DropZone?
    @State private var showConflictWarning = false
    
    var body: some View {
        ZStack {
            // Background action buttons
            HStack {
                // Edit button (left)
                if dragOffset.width > 0 {
                    HStack {
                        Button(action: {
                            resetOffset()
                            showingEdit = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Spacer()
                    }
                    .padding(.leading, 16)
                }
                
                Spacer()
                
                // Delete button (right)
                if dragOffset.width < 0 {
                    HStack {
                        Spacer()
                        Button(action: {
                            resetOffset()
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.trailing, 16)
                }
            }
            
            // Main task view
            ModernTaskBlockView(block: block)
                .offset(dragOffset)
                .scaleEffect(isDraggingToMove ? 1.05 : 1.0)
                .opacity(isDraggingToMove ? 0.9 : 1.0)
                .shadow(color: .pink.opacity(isDraggingToMove ? 0.4 : 0), radius: isDraggingToMove ? 15 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDraggingToMove)
                .onTapGesture {
                    // Move mode中は無視
                    guard !isDraggingToMove else { return }
                    
                    if isShowingActions {
                        resetOffset()
                    } else {
                        // 短いタップのみ編集画面を表示
                        showingEdit = true
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4) // より短い長押し時間
                        .onEnded { _ in
                            // Long press completed - enable move mode
                            isDraggingToMove = true
                            isAnyTaskFloating = true
                            dragStartTime = block.startTime
                            
                            // Reset any showing actions when entering move mode
                            if isShowingActions {
                                resetOffset()
                            }
                            
                            // Notify parent about drag start
                            onDragStart?(block)
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if isDraggingToMove {
                                // Move mode drag
                                dragOffset = value.translation
                                
                                // Notify parent about drag position for auto-scroll
                                onDragMove?(value.location)
                                
                                // Calculate drop zones if not already calculated
                                if dropZones.isEmpty {
                                    dropZones = calculateDropZones(for: block)
                                }
                                
                                // Find nearest drop zone based on drag position
                                nearestDropZone = findNearestDropZone(dragPosition: value.location)
                                
                                // Calculate new time based on vertical drag
                                if let startTime = dragStartTime {
                                    let timePerPoint: TimeInterval = 60 // 1 minute per point
                                    let timeOffset = Double(value.translation.height) * timePerPoint
                                    let newStartTime = startTime.addingTimeInterval(timeOffset)
                                    
                                    // Snap to 15-minute intervals
                                    let calendar = Calendar.current
                                    let minutes = calendar.component(.minute, from: newStartTime)
                                    let snappedMinutes = (minutes / 15) * 15
                                    
                                    var components = calendar.dateComponents([.year, .month, .day, .hour], from: newStartTime)
                                    components.minute = snappedMinutes
                                    let snappedTime = calendar.date(from: components) ?? newStartTime
                                    
                                    dragPreviewTime = snappedTime
                                    
                                    // Check for conflicts
                                    checkForConflicts(at: snappedTime)
                                }
                            }
                        }
                        .onEnded { value in
                            if isDraggingToMove {
                                if let dropZone = nearestDropZone, dropZone.isValidDrop {
                                    // Only allow drop if zone is valid (no conflicts)
                                    handleTaskDrop(to: dropZone)
                                } else if let newStartTime = dragPreviewTime {
                                    // Fallback to time-based positioning with strict conflict check
                                    let duration = block.endTime.timeIntervalSince(block.startTime)
                                    let newEndTime = newStartTime.addingTimeInterval(duration)
                                    
                                    // Always check for conflicts before allowing update
                                    let allTasks = viewModel.getTimeBlocks(for: Date()).filter { $0.id != block.id }
                                    let conflicts = findConflictingTasks(startTime: newStartTime, endTime: newEndTime, excluding: block.id, in: allTasks)
                                    
                                    if !conflicts.isEmpty {
                                        // Reject overlap - show error
                                        showOverlapError()
                                    } else {
                                        viewModel.updateTimeBlock(
                                            block,
                                            startTime: newStartTime,
                                            endTime: newEndTime
                                        )
                                        
                                        // Success haptic feedback
                                        let notificationFeedback = UINotificationFeedbackGenerator()
                                        notificationFeedback.notificationOccurred(.success)
                                    }
                                } else {
                                    // No valid position found - reject
                                    showOverlapError()
                                }
                                
                                // Notify parent about drag end
                                onDragEnd?()
                                
                                // Reset move mode
                                resetDragStates()
                            }
                        }
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 15) // 最小距離を増加
                        .onChanged { value in
                            // Only respond to horizontal swipes if not in move mode
                            if !isDraggingToMove {
                                let horizontalMovement = abs(value.translation.width)
                                let verticalMovement = abs(value.translation.height)
                                
                                // より厳密な水平判定
                                if horizontalMovement > verticalMovement && horizontalMovement > 25 {
                                    // Limit drag distance
                                    let maxDrag: CGFloat = 80
                                    dragOffset.width = max(-maxDrag, min(maxDrag, value.translation.width))
                                    isShowingActions = abs(dragOffset.width) > 30 // 閾値を上げる
                                }
                            }
                        }
                        .onEnded { value in
                            if !isDraggingToMove {
                                let threshold: CGFloat = 60 // 閾値を上げる
                                let horizontalMovement = abs(value.translation.width)
                                let verticalMovement = abs(value.translation.height)
                                
                                // より厳密な水平スワイプ判定
                                if horizontalMovement > verticalMovement && 
                                   horizontalMovement > 40 && // 最小移動距離を追加
                                   verticalMovement < 30 { // 垂直移動の上限を設定
                                    
                                    if value.translation.width > threshold {
                                        // Swipe right - show edit
                                        dragOffset.width = 80
                                        isShowingActions = true
                                        
                                        // Auto-hide after 4 seconds (延長)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            if dragOffset.width > 0 && isShowingActions {
                                                resetOffset()
                                            }
                                        }
                                    } else if value.translation.width < -threshold {
                                        // Swipe left - show delete
                                        dragOffset.width = -80
                                        isShowingActions = true
                                        
                                        // Auto-hide after 4 seconds (延長)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            if dragOffset.width < 0 && isShowingActions {
                                                resetOffset()
                                            }
                                        }
                                    } else {
                                        // Not enough swipe - reset
                                        resetOffset()
                                    }
                                } else {
                                    // Not a valid horizontal swipe - reset
                                    resetOffset()
                                }
                            }
                        }
                )
        }
            .sheet(isPresented: $showingEdit) {
                UnifiedTaskAddView(
                    viewModel: viewModel,
                    isPresented: $showingEdit,
                    existingBlock: block,
                    onSave: { updatedBlock in
                        viewModel.updateTimeBlock(updatedBlock)
                    },
                    onDelete: {
                        viewModel.deleteTimeBlock(block)
                    }
                )
            }
            .alert("タスクを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    viewModel.deleteTimeBlock(block)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("このタスクを削除してもよろしいですか？")
            }
    }
    
    private func resetOffset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
            isShowingActions = false
        }
    }
    
    private func resetDragStates() {
        // Notify parent about drag end if we were dragging
        if isDraggingToMove {
            onDragEnd?()
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
            isDraggingToMove = false
            isAnyTaskFloating = false
            isShowingActions = false
            dragStartTime = nil
            dragPreviewTime = nil
            dropZones = []
            nearestDropZone = nil
            showConflictWarning = false
        }
    }
    
    // MARK: - Drag & Drop Helper Methods
    
    private func calculateDropZones(for draggedTask: SDTimeBlock) -> [DropZone] {
        let allTasks = viewModel.getTimeBlocks(for: Date()).filter { $0.id != draggedTask.id }
        let sortedTasks = allTasks.sorted { $0.startTime < $1.startTime }
        
        var zones: [DropZone] = []
        let taskDuration = draggedTask.duration
        
        // Before first task
        if let firstTask = sortedTasks.first {
            let endTime = firstTask.startTime
            let startTime = endTime.addingTimeInterval(-taskDuration)
            let conflicts = findConflictingTasks(startTime: startTime, endTime: endTime, excluding: draggedTask.id, in: allTasks)
            
            zones.append(DropZone(
                insertPosition: 0,
                targetTime: startTime,
                rect: CGRect(x: 0, y: 0, width: 100, height: 30),
                isValidDrop: conflicts.isEmpty,
                conflictingTasks: conflicts
            ))
        }
        
        // Between tasks
        for i in 0..<sortedTasks.count-1 {
            let currentTask = sortedTasks[i]
            let nextTask = sortedTasks[i+1]
            
            let startTime = currentTask.endTime
            let endTime = startTime.addingTimeInterval(taskDuration)
            
            let conflicts = findConflictingTasks(startTime: startTime, endTime: endTime, excluding: draggedTask.id, in: allTasks)
            let fitsInGap = endTime <= nextTask.startTime
            
            zones.append(DropZone(
                insertPosition: i + 1,
                targetTime: startTime,
                rect: CGRect(x: 0, y: 0, width: 100, height: 30),
                isValidDrop: fitsInGap && conflicts.isEmpty,
                conflictingTasks: conflicts
            ))
        }
        
        // After last task
        if let lastTask = sortedTasks.last {
            let startTime = lastTask.endTime
            let endTime = startTime.addingTimeInterval(taskDuration)
            let conflicts = findConflictingTasks(startTime: startTime, endTime: endTime, excluding: draggedTask.id, in: allTasks)
            
            zones.append(DropZone(
                insertPosition: sortedTasks.count,
                targetTime: startTime,
                rect: CGRect(x: 0, y: 0, width: 100, height: 30),
                isValidDrop: conflicts.isEmpty,
                conflictingTasks: conflicts
            ))
        }
        
        return zones
    }
    
    private func findConflictingTasks(startTime: Date, endTime: Date, excluding taskId: UUID, in tasks: [SDTimeBlock]) -> [SDTimeBlock] {
        return tasks.filter { task in
            task.id != taskId && 
            !(endTime <= task.startTime || startTime >= task.endTime)
        }
    }
    
    private func findNearestDropZone(dragPosition: CGPoint) -> DropZone? {
        // This is a simplified implementation
        // In a real app, you'd calculate based on actual screen positions
        return dropZones.first { $0.isValidDrop }
    }
    
    private func checkForConflicts(at newStartTime: Date) {
        let newEndTime = newStartTime.addingTimeInterval(block.duration)
        let allTasks = viewModel.getTimeBlocks(for: Date())
        let conflicts = findConflictingTasks(startTime: newStartTime, endTime: newEndTime, excluding: block.id, in: allTasks)
        
        showConflictWarning = !conflicts.isEmpty
    }
    
    private func handleTaskDrop(to dropZone: DropZone) {
        if dropZone.isValidDrop {
            // Simple move without conflicts
            let newEndTime = dropZone.targetTime.addingTimeInterval(block.duration)
            viewModel.updateTimeBlock(block, startTime: dropZone.targetTime, endTime: newEndTime)
            
            // Success haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } else {
            // Reject overlap - show error and return to original position
            showOverlapError()
        }
    }
    
    private func showOverlapError() {
        // Error haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
        
        // Show visual feedback (could be expanded with alert or toast)
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = CGSize(width: 10, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.dragOffset = CGSize(width: -10, height: 0)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.dragOffset = .zero
            }
        }
        
        // Reset to original position
        resetDragStates()
    }
}