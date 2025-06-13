import SwiftUI

struct LongPressDeleteTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingActions = false
    @GestureState private var isPressed = false
    
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
                .offset(x: dragOffset.width)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                .onTapGesture {
                    if isShowingActions {
                        resetOffset()
                    } else {
                        showingEdit = true
                    }
                }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Only respond to primarily horizontal swipes
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            if horizontalMovement > verticalMovement {
                                // Limit drag distance
                                let maxDrag: CGFloat = 80
                                dragOffset.width = max(-maxDrag, min(maxDrag, value.translation.width))
                                isShowingActions = abs(dragOffset.width) > 20
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            // Only process if it's primarily a horizontal swipe
                            if horizontalMovement > verticalMovement {
                                if value.translation.width > threshold {
                                    // Swipe right - show edit
                                    dragOffset.width = 80
                                    
                                    // Auto-hide after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        if dragOffset.width > 0 {
                                            resetOffset()
                                        }
                                    }
                                } else if value.translation.width < -threshold {
                                    // Swipe left - show delete
                                    dragOffset.width = -80
                                    
                                    // Auto-hide after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        if dragOffset.width < 0 {
                                            resetOffset()
                                        }
                                    }
                                } else {
                                    // Not enough swipe - reset
                                    resetOffset()
                                }
                            } else {
                                // Vertical swipe - reset and allow scroll
                                resetOffset()
                            }
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            // Long press succeeded
                            showingDeleteAlert = true
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                        }
                        .updating($isPressed) { value, state, _ in
                            state = value
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
}