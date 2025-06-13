import SwiftUI
import UIKit
import SwiftData

// 時間を起床・就寝時間の範囲内に制限するグローバル関数
@MainActor
private func constrainToWakeSleepTime(_ time: Date, for date: Date) -> Date {
    let routineSettings = DailyRoutineSettings.shared
    let wakeTime = routineSettings.getWakeUpTime(for: date)
    let bedTime = routineSettings.getBedTime(for: date)
    
    // 起床時間より前の場合は起床時間に設定
    if time < wakeTime {
        return wakeTime
    }
    
    // 就寝時間より後の場合は就寝時間に設定
    if time > bedTime {
        return bedTime
    }
    
    return time
}

public struct MainView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var showingUnifiedTaskAdd = false
    @State private var suggestedStartTime: Date?
    @State private var suggestedEndTime: Date?
    @State private var showingStatistics = false
    @State private var showingRoutineSettings = false
    @State private var showingAnalytics = false
    @State private var showingCurrentActivity = false
    @State private var showingQuickActions = false
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var routineSettings = DailyRoutineSettings.shared
    
    // Reordering state
    @State private var isReorderMode = false
    @State private var reorderDraggedBlock: SDTimeBlock?
    @State private var reorderedBlocks: [SDTimeBlock] = []
    
    // Drag & Drop state for time adjustment
    @State private var draggedBlock: SDTimeBlock?
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragStartTime: Date?
    @State private var dragEndTime: Date?
    @State private var dragPreviewRect: CGRect = .zero
    @State private var dragPreviewTime: Date?
    @State private var dragPreviewDuration: TimeInterval = 3600
    
    // Global floating state to disable scroll
    @State private var isAnyTaskFloating = false
    
    // Timeline layout constants
    private let hourHeight: CGFloat = 80
    private let timeLineWidth: CGFloat = 50
    
    // Month calendar dates
    private var calendarDates: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: viewModel.selectedDate)?.start ?? viewModel.selectedDate
        let range = calendar.range(of: .day, in: .month, for: viewModel.selectedDate) ?? 0..<31
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Timeline Tab
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with month/year
                    headerView
                    
                    // Horizontal calendar
                    monthCalendarView
                        .padding(.horizontal)
                    
                    // Timeline content
                    ScrollView {
                        ZStack {
                            timelineContent
                                .padding(.horizontal, 16)
                            
                            // Drag preview overlay
                            if isDragging && dragStartTime != nil && dragEndTime != nil {
                                dragPreviewOverlay
                            }
                        }
                    }
                    .scrollDisabled(isAnyTaskFloating)
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            // Quick Action Buttons
                            if showingQuickActions {
                                QuickActionButtonsView(
                                    viewModel: viewModel,
                                    showingTaskAdd: $showingUnifiedTaskAdd
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Main FAB
                            Button(action: {
                                if showingQuickActions {
                                    suggestedStartTime = nil
                                    suggestedEndTime = nil
                                    showingUnifiedTaskAdd = true
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingQuickActions.toggle()
                                    }
                                }
                            }) {
                                Image(systemName: showingQuickActions ? "plus" : "ellipsis")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: Color.pink.opacity(0.4), radius: 12, x: 0, y: 8)
                                    .rotationEffect(.degrees(showingQuickActions ? 45 : 0))
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("タイムライン")
            }
            .tag(0)
            
            // Analytics Tab
            AnalyticsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("分析")
                }
                .tag(1)
            
            // AI suggestions tab removed
            
            // Current Activity Tab
            CurrentActivityView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("現在の活動")
                }
                .tag(2)
        }
            
        .accentColor(.pink)
        .sheet(isPresented: $showingUnifiedTaskAdd) {
            UnifiedTaskAddView(
                viewModel: viewModel,
                isPresented: $showingUnifiedTaskAdd,
                suggestedStartTime: suggestedStartTime,
                suggestedEndTime: suggestedEndTime
            )
        }
        .onChange(of: showingUnifiedTaskAdd) { oldValue, newValue in
            if oldValue && !newValue {
                // Sheet was dismissed, trigger refresh
                viewModel.refreshTrigger = UUID()
            }
        }
        .sheet(isPresented: $showingRoutineSettings) {
            DailyRoutineSettingsView()
        }
        .onChange(of: isReorderMode) { oldValue, newValue in
            if newValue && !oldValue && reorderedBlocks.isEmpty {
                // Auto-enabled reorder mode, initialize reordered blocks
                reorderedBlocks = getAllBlocksWithRoutine().sorted { $0.startTime < $1.startTime }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthYearText)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                
                Text("タイムライン")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Buttons removed
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var monthCalendarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    ForEach(calendarDates, id: \.self) { date in
                        MainCalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedDate = date
                                }
                            },
                            viewModel: viewModel
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    // 今日の日付にスクロール
                    let today = Calendar.current.startOfDay(for: Date())
                    proxy.scrollTo(today, anchor: .center)
                }
                .onChange(of: viewModel.selectedDate) {
                    withAnimation {
                        proxy.scrollTo(viewModel.selectedDate, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    private var timelineContent: some View {
        // Force refresh when trigger changes
        let _ = viewModel.refreshTrigger
        
        // Get all blocks including routine tasks
        let allBlocks = isReorderMode && !reorderedBlocks.isEmpty ? reorderedBlocks : getAllBlocksWithRoutine()
            .sorted { $0.startTime < $1.startTime }
        
        // Calculate overlapping groups
        let overlapGroups = calculateOverlapGroups(blocks: allBlocks)
        
        return LazyVStack(spacing: 0) {
            // Reorder mode helper
            if isReorderMode {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.pink)
                        
                        Text("タスクを長押ししてドラッグで並べ替え")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("完了したら右上の✓をタップ")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.pink.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            if allBlocks.isEmpty {
                // Empty state with rectangular add button
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("今日はまだタスクがありません")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("最初のタスクを追加してスケジュールを始めましょう")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Rectangular add task button
                    AddTaskButtonView(
                        title: "最初のタスクを追加",
                        subtitle: "1日のスケジュールを開始",
                        action: {
                            suggestedStartTime = nil
                            suggestedEndTime = nil
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showingUnifiedTaskAdd = true
                            }
                        }
                    )
                }
                .padding(.top, 80)
            } else {
                // Display overlapping groups
                ForEach(Array(overlapGroups.enumerated()), id: \.offset) { groupIndex, group in
                    if group.blocks.count > 1 {
                        // Overlapping tasks - display with improved UI
                        ImprovedOverlappingTasksView(
                            group: group,
                            viewModel: viewModel,
                            selectedDate: viewModel.selectedDate,
                            isAnyTaskFloating: $isAnyTaskFloating,
                            isFirst: groupIndex == 0,
                            isLast: groupIndex == overlapGroups.count - 1,
                            onAddTask: { startTime in
                                suggestedStartTime = constrainToWakeSleepTime(startTime, for: viewModel.selectedDate)
                                let endTime = startTime.addingTimeInterval(3600)
                                suggestedEndTime = constrainToWakeSleepTime(endTime, for: viewModel.selectedDate)
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showingUnifiedTaskAdd = true
                                }
                            }
                        )
                    } else {
                        // Single task - display normally
                        ForEach(group.blocks) { block in
                            DraggableVerticalTaskView(
                                block: block,
                                viewModel: viewModel,
                                isReorderMode: $isReorderMode,
                                draggedBlock: $reorderDraggedBlock,
                                onReorder: handleReorder
                            )
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Add gap indicator between groups
                    if groupIndex < overlapGroups.count - 1 {
                        let currentGroupEnd = group.blocks.map { $0.endTime }.max()!
                        let nextGroupStart = overlapGroups[groupIndex + 1].blocks.map { $0.startTime }.min()!
                        let gapDuration = nextGroupStart.timeIntervalSince(currentGroupEnd)
                        
                        if gapDuration >= 3600 { // Show gap if 1 hour or more
                            ChainGapDisplayView(
                                fromTime: currentGroupEnd,
                                toTime: nextGroupStart,
                                onAddTask: { startTime in
                                    suggestedStartTime = currentGroupEnd
                                    suggestedEndTime = currentGroupEnd.addingTimeInterval(3600)
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        showingUnifiedTaskAdd = true
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Add next task button only if not ending with bedtime
                if !allBlocks.isEmpty {
                    let lastBlock = allBlocks.last!
                    let isBedtimeTask = lastBlock.title.contains("就寝") || lastBlock.title.contains("寝る") || lastBlock.title.contains("睡眠")
                    
                    // Next task add button - only show if not bedtime
                    if !isBedtimeTask {
                        TimelineAddButtonView(
                            previousEndTime: lastBlock.endTime,
                            isLastButton: true,
                            action: { startTime in
                                suggestedStartTime = startTime
                                suggestedEndTime = startTime.addingTimeInterval(3600) // Default 1 hour
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showingUnifiedTaskAdd = true
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var dragPreviewOverlay: some View {
        HStack {
            Spacer()
                .frame(width: timeLineWidth + 16)
            
            VStack {
                if let startTime = dragStartTime, let endTime = dragEndTime {
                    let calendar = Calendar.current
                    let actualStartTime = min(startTime, endTime)
                    let actualEndTime = max(startTime, endTime)
                    
                    let startHour = calendar.component(.hour, from: actualStartTime)
                    let startMinute = calendar.component(.minute, from: actualStartTime)
                    let endHour = calendar.component(.hour, from: actualEndTime)
                    let endMinute = calendar.component(.minute, from: actualEndTime)
                    
                    let startOffset = CGFloat(startHour) * hourHeight + CGFloat(startMinute) / 60.0 * hourHeight
                    let endOffset = CGFloat(endHour) * hourHeight + CGFloat(endMinute) / 60.0 * hourHeight
                    let height = endOffset - startOffset
                    
                    Spacer()
                        .frame(height: startOffset)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pink.opacity(0.3))
                        .stroke(Color.pink, lineWidth: 2)
                        .frame(height: max(30, height))
                        .overlay(
                            VStack(spacing: 4) {
                                Text("新しいタスク")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(formatTimeRange(start: actualStartTime, end: actualEndTime))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)
        let duration = Int(end.timeIntervalSince(start) / 60)
        
        return "\(startTime)〜\(endTime) (\(duration)分)"
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private func getBlocksForHour(_ hour: Int) -> [SDTimeBlock] {
        let blocks = viewModel.getTimeBlocks(for: viewModel.selectedDate)
        let calendar = Calendar.current
        
        return blocks.filter { block in
            let blockHour = calendar.component(.hour, from: block.startTime)
            return blockHour == hour || 
                   (calendar.component(.hour, from: block.endTime) == hour && 
                    calendar.component(.minute, from: block.endTime) > 0) ||
                   (blockHour < hour && calendar.component(.hour, from: block.endTime) > hour)
        }
    }
    
    private func createTimeForHour(_ hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents) ?? viewModel.selectedDate
    }
    
    // MARK: - Helper Functions
    
    
    private func isSameTimeRange(_ block1: SDTimeBlock, _ block2: SDTimeBlock) -> Bool {
        let calendar = Calendar.current
        let hour1 = calendar.component(.hour, from: block1.startTime)
        let hour2 = calendar.component(.hour, from: block2.startTime)
        return abs(hour1 - hour2) <= 1 // Same or adjacent hour
    }
    
    // MARK: - Drag Handling
    private func handleDragChanged(value: DragGesture.Value, startTime: Date) {
        if !isDragging {
            isDragging = true
            dragStartLocation = value.startLocation
            dragStartTime = startTime
            
            // Provide haptic feedback when drag starts
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        let deltaY = value.translation.height
        let endTime = startTime.addingTimeInterval((deltaY / hourHeight) * 3600)
        
        // Snap both times to 15-minute intervals
        let calendar = Calendar.current
        
        // Snap start time
        let startMinute = calendar.component(.minute, from: startTime)
        let snappedStartMinute = (startMinute / 15) * 15
        var startComponents = calendar.dateComponents([.year, .month, .day, .hour], from: startTime)
        startComponents.minute = snappedStartMinute
        
        // Snap end time  
        let endMinute = calendar.component(.minute, from: endTime)
        let snappedEndMinute = (endMinute / 15) * 15
        var endComponents = calendar.dateComponents([.year, .month, .day, .hour], from: endTime)
        endComponents.minute = snappedEndMinute
        
        if let snappedStartTime = calendar.date(from: startComponents),
           let snappedEndTime = calendar.date(from: endComponents) {
            dragStartTime = snappedStartTime
            dragEndTime = snappedEndTime
        }
    }
    
    // MARK: - Get All Blocks Including Routine
    private func getAllBlocksWithRoutine() -> [SDTimeBlock] {
        var allBlocks = viewModel.getTimeBlocks(for: viewModel.selectedDate)
        
        // Add routine tasks if enabled
        if routineSettings.isRoutineEnabled {
            let routineTasks = routineSettings.generateRoutineTasks(for: viewModel.selectedDate)
            
            for routine in routineTasks {
                // Check if routine task already exists
                let routineExists = allBlocks.contains { block in
                    let calendar = Calendar.current
                    return block.title == routine.title &&
                           calendar.isDate(block.startTime, equalTo: routine.startTime, toGranularity: .minute)
                }
                
                if !routineExists {
                    // Create temporary routine block
                    if let category = viewModel.getCategories().first(where: { $0.name == routine.categoryName }) {
                        // Create a temporary block for display
                        let routineBlock = SDTimeBlock(
                            title: routine.title,
                            startTime: routine.startTime,
                            endTime: routine.endTime,
                            category: category,
                            notes: "毎日の固定ルーティン",
                            isCompleted: false
                        )
                        // Mark as routine for special styling
                        routineBlock.isRoutine = true
                        allBlocks.append(routineBlock)
                    }
                }
            }
        }
        
        return allBlocks
    }
    
    // MARK: - Overlap Calculation
    private func calculateOverlapGroups(blocks: [SDTimeBlock]) -> [OverlapGroup] {
        var groups: [OverlapGroup] = []
        var processedBlocks = Set<String>()
        
        for block in blocks {
            if processedBlocks.contains(block.id.uuidString) { continue }
            
            var group = OverlapGroup(blocks: [block])
            processedBlocks.insert(block.id.uuidString)
            
            // Find all blocks that overlap with this group
            for otherBlock in blocks {
                if processedBlocks.contains(otherBlock.id.uuidString) { continue }
                
                // Check if otherBlock overlaps with any block in the current group
                let overlaps = group.blocks.contains { existingBlock in
                    return blocksOverlap(existingBlock, otherBlock)
                }
                
                if overlaps {
                    group.blocks.append(otherBlock)
                    processedBlocks.insert(otherBlock.id.uuidString)
                }
            }
            
            // Assign column positions to blocks in the group
            assignColumnPositions(to: &group)
            groups.append(group)
        }
        
        return groups.sorted { $0.startTime < $1.startTime }
    }
    
    private func blocksOverlap(_ block1: SDTimeBlock, _ block2: SDTimeBlock) -> Bool {
        return block1.startTime < block2.endTime && block2.startTime < block1.endTime
    }
    
    private func assignColumnPositions(to group: inout OverlapGroup) {
        group.blocks.sort { $0.startTime < $1.startTime }
        
        for (index, block) in group.blocks.enumerated() {
            // Find the first available column
            var column = 0
            var columnFound = false
            
            while !columnFound {
                columnFound = true
                
                // Check if this column is available
                for previousBlock in group.blocks[0..<index] {
                    if let prevColumn = group.columnPositions[previousBlock.id],
                       prevColumn == column,
                       blocksOverlap(previousBlock, block) {
                        columnFound = false
                        column += 1
                        break
                    }
                }
            }
            
            group.columnPositions[block.id] = column
        }
        
        // Calculate total columns
        group.totalColumns = (group.columnPositions.values.max() ?? 0) + 1
    }
    
    private func handleDragEnded(value: DragGesture.Value, startTime: Date) {
        defer {
            isDragging = false
            dragStartTime = nil
            dragEndTime = nil
        }
        
        guard let finalStartTime = dragStartTime,
              let finalEndTime = dragEndTime else { return }
        
        // Create new task if drag was significant
        if abs(value.translation.height) > 30 {
            let actualStartTime = min(finalStartTime, finalEndTime)
            let actualEndTime = max(finalStartTime, finalEndTime)
            
            // Ensure minimum duration of 15 minutes
            let duration = actualEndTime.timeIntervalSince(actualStartTime)
            let adjustedEndTime = duration < 900 ? actualStartTime.addingTimeInterval(900) : actualEndTime
            
            suggestedStartTime = actualStartTime
            suggestedEndTime = adjustedEndTime
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showingUnifiedTaskAdd = true
            }
            
            // Provide success haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Reorder Functions
    
    private func toggleReorderMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isReorderMode.toggle()
            if isReorderMode {
                reorderedBlocks = getAllBlocksWithRoutine().sorted { $0.startTime < $1.startTime }
            } else {
                // Apply the reordered times when exiting reorder mode
                applyReorderedTimes()
            }
        }
    }
    
    private func handleReorder(_ source: SDTimeBlock, _ destination: SDTimeBlock) {
        var blocks = reorderedBlocks.isEmpty ? getAllBlocksWithRoutine().sorted(by: { $0.startTime < $1.startTime }) : reorderedBlocks
        
        // Find indices
        guard let sourceIndex = blocks.firstIndex(where: { $0.id == source.id }),
              let destIndex = blocks.firstIndex(where: { $0.id == destination.id }) else { return }
        
        // Remove and insert
        let movedBlock = blocks.remove(at: sourceIndex)
        blocks.insert(movedBlock, at: destIndex)
        
        // Update the reordered blocks
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            reorderedBlocks = blocks
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func applyReorderedTimes() {
        guard !reorderedBlocks.isEmpty else { return }
        
        var currentTime = reorderedBlocks.first?.startTime ?? Date()
        
        // Update each block's time based on the new order
        for (index, block) in reorderedBlocks.enumerated() {
            let duration = block.endTime.timeIntervalSince(block.startTime)
            
            // Skip routine blocks as they have fixed times
            if block.isRoutine {
                currentTime = block.endTime
                continue
            }
            
            // Add 5 minute gap between tasks
            if index > 0 {
                currentTime = currentTime.addingTimeInterval(300) // 5 minutes
            }
            
            let newEndTime = currentTime.addingTimeInterval(duration)
            
            // Update the block with new times
            viewModel.updateTimeBlock(block, startTime: currentTime, endTime: newEndTime)
            
            currentTime = newEndTime
        }
        
        // Clear reordered blocks
        reorderedBlocks = []
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

struct MainCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(weekdayFormatter.string(from: date))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(dayFormatter.string(from: date))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? 
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : 
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                            )
                    )
                
                // Task indicator
                Circle()
                    .fill(.pink)
                    .frame(width: 4, height: 4)
                    .opacity(hasTasksOnDate ? 1.0 : 0.0)
            }
        }
        .frame(width: 50)
    }
    
    private var hasTasksOnDate: Bool {
        !viewModel.getTimeBlocks(for: date).isEmpty
    }
}

struct InteractiveHourRowView: View {
    let hour: Int
    let blocks: [SDTimeBlock]
    let selectedDate: Date
    let viewModel: SwiftDataTimeTrackingViewModel
    let hourHeight: CGFloat
    let timeLineWidth: CGFloat
    @Binding var isAnyTaskFloating: Bool
    let onTapEmptySpace: (Int) -> Void
    let onDragChanged: (DragGesture.Value, Date) -> Void
    let onDragEnded: (DragGesture.Value, Date) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time label
            VStack(spacing: 4) {
                Text(String(format: "%02d:00", hour))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                // Dotted line connector
                VStack(spacing: 4) {
                    ForEach(0..<8, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2, height: 2)
                    }
                }
                .frame(height: hourHeight - 16)
            }
            .frame(width: timeLineWidth)
            
            // Content area with drag support
            ZStack {
                // Background drag area
                dragBackgroundArea
                
                // Existing task blocks
                VStack(alignment: .leading, spacing: 8) {
                    if blocks.isEmpty {
                        emptySpaceView
                    } else {
                        ForEach(blocks) { block in
                            LongPressDeleteTaskView(
                                block: block,
                                viewModel: viewModel
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            
            Spacer()
        }
        .frame(height: hourHeight)
    }
    
    private var dragBackgroundArea: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let startTime = createTimeForDrag(hour: hour, dragLocation: value.startLocation)
                        onDragChanged(value, startTime)
                    }
                    .onEnded { value in
                        let startTime = createTimeForDrag(hour: hour, dragLocation: value.startLocation)
                        onDragEnded(value, startTime)
                    }
            )
    }
    
    private var emptySpaceView: some View {
        Group {
            // 睡眠時間（夜22時〜朝6時）のみ左側にテキストを表示
            if isSleepingHour(hour) {
                Button(action: { onTapEmptySpace(0) }) {
                    HStack {
                        Text(sleepingTimeText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .frame(height: hourHeight - 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // それ以外の時間は空き時間の促しとタスク追加ボタンを表示
                Color.clear
                    .frame(height: hourHeight - 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTapEmptySpace(0)
                    }
            }
        }
    }
    
    private func isSleepingHour(_ hour: Int) -> Bool {
        // 夜22時〜朝6時を睡眠時間とする
        return hour >= 22 || hour < 6
    }
    
    private var sleepingTimeText: String {
        if hour >= 22 || hour <= 3 {
            return "おやすみなさい"
        } else {
            return "おはようございます"
        }
    }
    
    private func createTimeForDrag(hour: Int, dragLocation: CGPoint) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Calculate minute based on y position within the hour
        let minuteInHour = Int((dragLocation.y / hourHeight) * 60)
        let clampedMinute = max(0, min(59, minuteInHour))
        
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = clampedMinute
        
        return calendar.date(from: dateComponents) ?? selectedDate
    }
}

struct ModernTaskBlockView: View {
    let block: SDTimeBlock
    @State private var showingEdit = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @FocusState private var isTitleFieldFocused: Bool
    
    var body: some View {
        Button(action: { 
            if !isEditing {
                showingEdit = true
            }
        }) {
            HStack(spacing: 12) {
                // Left side: Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [block.color, block.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if block.isRoutine {
                        // Special icon for routine tasks
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: block.category?.icon ?? "circle")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: block.color.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Right side: Task info
                VStack(alignment: .leading, spacing: 4) {
                    // Duration and status
                    HStack {
                        Text(durationText)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(block.color)
                        
                        Spacer()
                        
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Title - Editable
                    if isEditing {
                        TextField("タイトル", text: $editingTitle)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isTitleFieldFocused)
                            .onSubmit {
                                saveTitle()
                            }
                    } else {
                        Text(block.title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .onTapGesture {
                                startEditingTitle()
                            }
                    }
                    
                    // Time range
                    Text(timeText)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)
                    
                    // Notes if available
                    if !block.notes.isEmpty {
                        Text(block.notes)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: block.isRoutine ? [
                                Color(white: 0.15).opacity(0.8),
                                Color(white: 0.10).opacity(0.8)
                            ] : [
                                Color(white: 0.12),
                                Color(white: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                block.isRoutine ? 
                                    block.color.opacity(0.5) : 
                                    block.color.opacity(0.3),
                                lineWidth: block.isRoutine ? 2 : 1
                            )
                    )
                    .overlay(
                        // Badge for routine tasks
                        block.isRoutine ? 
                        HStack {
                            Spacer()
                            VStack {
                                Text("毎日")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(block.color.opacity(0.8))
                                    )
                                    .padding(8)
                                Spacer()
                            }
                        } : nil
                    )
            )
            .shadow(color: block.color.opacity(0.2), radius: 6, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    if isEditing {
                        // Don't trigger button action while editing
                    }
                }
        )
    }
    
    private func startEditingTitle() {
        editingTitle = block.title
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTitleFieldFocused = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveTitle() {
        if !editingTitle.isEmpty && editingTitle != block.title {
            block.title = editingTitle
            // Save through view model if needed
            // viewModel.updateTimeBlock(block, title: editingTitle)
            
            // Success feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        isEditing = false
        isTitleFieldFocused = false
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
    
    private var durationText: String {
        let duration = Int(block.duration / 60)
        if duration >= 60 {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes > 0 {
                return "\(hours)h\(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(duration)m"
        }
    }
    
    private var statusColor: Color {
        if block.isCompleted {
            return .teal
        } else {
            return .pink
        }
    }
}

// MARK: - Supporting Views for Task-based Timeline

struct TimelineRowView: View {
    let block: SDTimeBlock?
    let viewModel: SwiftDataTimeTrackingViewModel
    let selectedDate: Date
    @Binding var isAnyTaskFloating: Bool
    let isFirst: Bool
    let isLast: Bool
    let nextBlock: SDTimeBlock?
    let lastEndTime: Date?
    let onAddTask: ((Date) -> Void)?
    
    init(block: SDTimeBlock?, viewModel: SwiftDataTimeTrackingViewModel, selectedDate: Date, isAnyTaskFloating: Binding<Bool>, isFirst: Bool, isLast: Bool, nextBlock: SDTimeBlock?, lastEndTime: Date? = nil, onAddTask: ((Date) -> Void)? = nil) {
        self.block = block
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self._isAnyTaskFloating = isAnyTaskFloating
        self.isFirst = isFirst
        self.isLast = isLast
        self.nextBlock = nextBlock
        self.lastEndTime = lastEndTime
        self.onAddTask = onAddTask
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let block = block {
                // Task without chain design
                LongPressDeleteTaskView(
                    block: block,
                    viewModel: viewModel
                )
                .padding(.vertical, 8)
                
            } else if let lastEndTime = lastEndTime {
                // Final gap indicator (display only)
                ChainGapDisplayView(
                    fromTime: lastEndTime,
                    toTime: nil
                )
            }
        }
    }
    
    private var timeText: String {
        guard let block = block else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: block.startTime)
    }
    
    private var endTimeText: String {
        guard let lastEndTime = lastEndTime else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: lastEndTime)
    }
    
    private var hasGapBefore: Bool {
        // Logic to determine if there's a significant gap before this task
        // This would be determined by the parent view based on time differences
        return false // Simplified for now
    }
    
    private var hasGapAfter: Bool {
        guard let block = block, let nextBlock = nextBlock else { return isLast }
        let gapDuration = nextBlock.startTime.timeIntervalSince(block.endTime)
        return gapDuration > 300 // More than 5 minutes gap
    }
}

struct TimeMarkerView: View {
    let time: Date
    let label: String
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(timeText)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
            
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.6), .pink.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct ChainGapDisplayView: View {
    let fromTime: Date
    let toTime: Date?
    let onAddTask: ((Date) -> Void)?
    
    init(fromTime: Date, toTime: Date?, onAddTask: ((Date) -> Void)? = nil) {
        self.fromTime = fromTime
        self.toTime = toTime
        self.onAddTask = onAddTask
    }
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "空き時間"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の休憩"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の休憩"
            } else {
                return "\(hours)時間\(remainingMinutes)分の休憩"
            }
        }
    }
    
    var body: some View {
        let duration = toTime?.timeIntervalSince(fromTime) ?? 0
        let isLongGap = duration >= 3600 // 1 hour or more
        
        VStack(spacing: 0) {
            // Centered chain connection with dotted line
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .frame(height: 20)
            
            // Gap display with integrated add button
            Button(action: {
                if let onAddTask = onAddTask {
                    onAddTask(fromTime)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(gapText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isLongGap, let _ = onAddTask {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(.caption2, design: .rounded))
                            Text("追加")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.pink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isLongGap && onAddTask != nil ? Color.pink.opacity(0.3) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .disabled(onAddTask == nil || !isLongGap)
        }
    }
}

struct TimelineGapRowView: View {
    let fromTime: Date
    let toTime: Date?
    let onTap: () -> Void
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "時間の余裕があります？体調の計画を立てましょう。"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の余裕があります"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の余裕があります"
            } else {
                return "\(hours)時間\(remainingMinutes)分の余裕があります"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text(gapText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.pink.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineHeaderView: View {
    let time: Date
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
    
    private var dateText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        switch hour {
        case 0..<6:
            return "深夜"
        case 6..<12:
            return "午前"
        case 12..<18:
            return "午後"
        case 18..<22:
            return "夕方"
        default:
            return "夜"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(timeText)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

struct TimelineGapView: View {
    let fromTime: Date
    let toTime: Date?
    let onTap: () -> Void
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "次のタスクを追加"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の空き時間"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の空き時間"
            } else {
                return "\(hours)時間\(remainingMinutes)分の空き時間"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Dotted line
                HStack {
                    ForEach(0..<20, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                }
                
                // Gap info
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pink)
                    
                    Text(gapText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// MARK: - Task Add Button Components

struct AddTaskButtonView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.title2, design: .rounded))
                        .foregroundColor(.pink)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineAddButtonView: View {
    let previousEndTime: Date?
    let isLastButton: Bool
    let action: (Date) -> Void
    
    private var nextStartTime: Date {
        guard let endTime = previousEndTime else {
            // If no previous task, start from next hour
            let calendar = Calendar.current
            let now = Date()
            let nextHour = calendar.dateInterval(of: .hour, for: now)?.end ?? now
            return nextHour
        }
        
        // Start 15 minutes after the previous task ends
        return endTime.addingTimeInterval(900)
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: nextStartTime)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top chain connector
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .frame(height: 20)
            
            Button(action: {
                action(nextStartTime)
            }) {
                // Add button content
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.pink.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("次のタスクを追加")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("\(timeText)から開始")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.pink.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Overlap Group Model
struct OverlapGroup {
    var blocks: [SDTimeBlock]
    var columnPositions: [UUID: Int] = [:]
    var totalColumns: Int = 1
    
    var startTime: Date {
        blocks.map { $0.startTime }.min() ?? Date()
    }
    
    var endTime: Date {
        blocks.map { $0.endTime }.max() ?? Date()
    }
}

// MARK: - Overlapping Tasks View
struct OverlappingTasksView: View {
    let group: OverlapGroup
    let viewModel: SwiftDataTimeTrackingViewModel
    let selectedDate: Date
    @Binding var isAnyTaskFloating: Bool
    let isFirst: Bool
    let isLast: Bool
    let onAddTask: ((Date) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Time header with overlap indicator
            HStack {
                TimeMarkerView(time: group.startTime, label: formatTimeRange())
                
                Spacer()
                
                // Overlap indicator badge
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("\(group.blocks.count)件の重複")
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.2))
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Overlapping tasks container with improved layout
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(group.blocks.enumerated()), id: \.element.id) { index, block in
                        VStack(spacing: 8) {
                            // Time range for each task
                            Text(formatBlockTime(block))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.gray)
                            
                            LongPressDeleteTaskView(
                                block: block,
                                viewModel: viewModel
                            )
                            .frame(width: 200)
                            .overlay(
                                // Overlap number indicator
                                VStack {
                                    HStack {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(index + 1)")
                                                    .font(.system(.caption2, design: .rounded))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: calculateGroupHeight() + 30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.05),
                                Color.red.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .padding(.vertical, 8)
        }
    }
    
    private func calculateGroupHeight() -> CGFloat {
        let maxHeight = group.blocks.map { block in
            let duration = block.endTime.timeIntervalSince(block.startTime)
            return CGFloat(duration / 3600) * 80 + 20 // hourHeight + padding
        }.max() ?? 100
        
        return max(100, maxHeight)
    }
    
    private func formatTimeRange() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        
        let startTime = formatter.string(from: group.startTime)
        let endTime = formatter.string(from: group.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
    
    private func formatBlockTime(_ block: SDTimeBlock) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SDTimeBlock.self, SDCategory.self, SDTag.self, SDTaskTemplate.self])
}