import SwiftUI

struct LongPressDeleteTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    var body: some View {
        ModernTaskBlockView(block: block)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                showingEdit = true
            }
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity) {
                // Long press succeeded
                showingDeleteAlert = true
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
            .contextMenu {
                Button(action: {
                    showingEdit = true
                }) {
                    Label("編集", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("削除", systemImage: "trash")
                }
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
}