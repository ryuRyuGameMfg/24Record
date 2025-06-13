import SwiftUI
import SwiftData
import UIKit

struct TaskDropDelegate: DropDelegate {
    let destinationBlock: SDTimeBlock
    @Binding var draggedBlock: SDTimeBlock?
    let onReorder: (SDTimeBlock, SDTimeBlock) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedBlock = draggedBlock else { return false }
        
        if draggedBlock.id != destinationBlock.id {
            onReorder(draggedBlock, destinationBlock)
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when hovering over drop target
    }
    
    func dropExited(info: DropInfo) {
        // Reset visual feedback
    }
}

struct DraggableVerticalTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @Binding var isReorderMode: Bool
    @Binding var draggedBlock: SDTimeBlock?
    let onReorder: (SDTimeBlock, SDTimeBlock) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @GestureState private var longPressState = false
    @State private var hasStartedDrag = false
    
    // Calculate height based on duration (1 hour = 80 points)
    private var taskHeight: CGFloat {
        let duration = block.endTime.timeIntervalSince(block.startTime)
        let hours = duration / 3600
        return max(40, hours * 80) // Minimum height of 40
    }
    
    var body: some View {
        VerticalTaskView(
            block: block,
            viewModel: viewModel,
            isReorderMode: $isReorderMode
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(isDragging ? 0.8 : 0))
        )
        .offset(dragOffset)
        .scaleEffect(isDragging || longPressState ? 0.98 : 1.0)
        .opacity(isDragging ? 0.9 : 1.0)
        .zIndex(isDragging ? 1000 : 0)
        .overlay(
            // Visual feedback when ready to drag
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pink.opacity(longPressState && !isDragging ? 0.3 : 0), lineWidth: 2)
        )
        .shadow(color: .pink.opacity(isDragging ? 0.4 : 0), radius: isDragging ? 15 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: longPressState)
        .frame(height: taskHeight)
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .updating($longPressState) { value, state, _ in
                    state = value
                }
                .onEnded { _ in
                    // Long press recognized
                    if !isReorderMode {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isReorderMode = true
                        }
                    }
                    
                    if !hasStartedDrag {
                        hasStartedDrag = true
                        draggedBlock = block
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if hasStartedDrag {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    // Reset everything
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        isDragging = false
                        hasStartedDrag = false
                        draggedBlock = nil
                    }
                    
                    // Success feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
        )
        .onDrop(of: [.text], delegate: TaskDropDelegate(
            destinationBlock: block,
            draggedBlock: $draggedBlock,
            onReorder: onReorder
        ))
    }
}