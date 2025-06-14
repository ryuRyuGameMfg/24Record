import SwiftUI

struct DraggableTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var currentDragTime: Date?
    @State private var showTimePreview = false
    @State private var isEditingTime = false
    
    private let hourHeight: CGFloat = 80
    private let minuteHeight: CGFloat = 80.0 / 60.0
    
    var body: some View {
        ZStack {
            // Main task view
            ModernTaskBlockView(block: block)
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadow(
                    color: isDragging ? block.color.opacity(0.4) : .clear,
                    radius: isDragging ? 12 : 0,
                    x: 0,
                    y: isDragging ? 6 : 0
                )
                .offset(dragOffset)
                .overlay(
                    // Drag handles for time adjustment
                    Group {
                        if isEditingTime {
                            VStack {
                                // Top handle for start time
                                DragHandle(edge: .top)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                adjustStartTime(by: value.translation.height)
                                            }
                                            .onEnded { _ in
                                                commitTimeChange()
                                            }
                                    )
                                
                                Spacer()
                                
                                // Bottom handle for end time
                                DragHandle(edge: .bottom)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                adjustEndTime(by: value.translation.height)
                                            }
                                            .onEnded { _ in
                                                commitTimeChange()
                                            }
                                    )
                            }
                        }
                    }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isEditingTime {
                                handleDrag(value)
                            }
                        }
                        .onEnded { value in
                            if !isEditingTime {
                                handleDragEnd(value)
                            }
                        }
                )
                .onLongPressGesture(minimumDuration: 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isEditingTime.toggle()
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            
            // Time preview during drag
            if isDragging && showTimePreview, let dragTime = currentDragTime {
                VStack {
                    TimePreviewBadge(time: dragTime)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .offset(y: -40)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditingTime)
    }
    
    private func handleDrag(_ value: DragGesture.Value) {
        withAnimation(.interactiveSpring()) {
            isDragging = true
            dragOffset = value.translation
            
            // Calculate new time based on drag
            let minutesOffset = Int(value.translation.height / minuteHeight)
            if let newTime = Calendar.current.date(byAdding: .minute, value: minutesOffset, to: block.startTime) {
                currentDragTime = newTime
                showTimePreview = true
            }
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            let minutesOffset = Int(value.translation.height / minuteHeight)
            
            // Update task time
            if abs(minutesOffset) >= 5 { // Minimum 5 minutes change
                updateTaskTime(minutesOffset: minutesOffset)
            }
            
            // Reset drag state
            isDragging = false
            dragOffset = .zero
            showTimePreview = false
            currentDragTime = nil
        }
    }
    
    private func adjustStartTime(by offset: CGFloat) {
        let minutesOffset = Int(offset / minuteHeight)
        if let newStartTime = Calendar.current.date(byAdding: .minute, value: minutesOffset, to: block.startTime) {
            // Ensure start time doesn't go past end time
            if newStartTime < block.endTime {
                block.startTime = newStartTime
                
                // Visual feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func adjustEndTime(by offset: CGFloat) {
        let minutesOffset = Int(offset / minuteHeight)
        if let newEndTime = Calendar.current.date(byAdding: .minute, value: minutesOffset, to: block.endTime) {
            // Ensure end time doesn't go before start time
            if newEndTime > block.startTime {
                block.endTime = newEndTime
                
                // Visual feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func commitTimeChange() {
        // Save changes through view model
        viewModel.updateTimeBlock(block)
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func updateTaskTime(minutesOffset: Int) {
        let calendar = Calendar.current
        
        if let newStartTime = calendar.date(byAdding: .minute, value: minutesOffset, to: block.startTime),
           let newEndTime = calendar.date(byAdding: .minute, value: minutesOffset, to: block.endTime) {
            
            // Update the block times
            block.startTime = newStartTime
            block.endTime = newEndTime
            
            // Save through view model
            viewModel.updateTimeBlock(block)
            
            // Success feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
}

struct DragHandle: View {
    let edge: Edge
    
    var body: some View {
        HStack {
            if edge == .top {
                Image(systemName: "line.3.horizontal")
                    .font(.system(.caption2))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pink)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                Spacer()
            } else {
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .font(.system(.caption2))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pink)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 8)
    }
}

struct TimePreviewBadge: View {
    let time: Date
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
    
    var body: some View {
        Text(timeText)
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.pink)
                    .shadow(color: Color.pink.opacity(0.5), radius: 8, x: 0, y: 4)
            )
    }
}