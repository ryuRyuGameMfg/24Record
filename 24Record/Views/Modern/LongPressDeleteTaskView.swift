import SwiftUI

struct LongPressDeleteTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    
    init(block: SDTimeBlock, viewModel: SwiftDataTimeTrackingViewModel) {
        self.block = block
        self.viewModel = viewModel
    }
    
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingActions = false
    
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
            
            // Main task view with improved animations
            ModernTaskBlockView(block: block)
                .offset(dragOffset)
                .scaleEffect(isShowingActions ? 0.98 : 1.0)
                .shadow(color: .black.opacity(isShowingActions ? 0.2 : 0), radius: isShowingActions ? 8 : 0, y: isShowingActions ? 4 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                .animation(.spring(response: 0.2, dampingFraction: 0.9), value: isShowingActions)
                .onTapGesture {
                    if isShowingActions {
                        resetOffset()
                    } else {
                        showingEdit = true
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 10) // More sensitive
                        .onChanged { value in
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            // More lenient gesture recognition
                            if horizontalMovement > verticalMovement && horizontalMovement > 15 {
                                let maxDrag: CGFloat = 80
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset.width = max(-maxDrag, min(maxDrag, value.translation.width))
                                    isShowingActions = abs(dragOffset.width) > 25
                                }
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50 // Lower threshold
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if horizontalMovement > verticalMovement && 
                                   horizontalMovement > 30 && 
                                   verticalMovement < 40 {
                                    
                                    if value.translation.width > threshold {
                                        // Swipe right - show edit
                                        dragOffset.width = 80
                                        isShowingActions = true
                                        
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            if dragOffset.width > 0 && isShowingActions {
                                                resetOffset()
                                            }
                                        }
                                    } else if value.translation.width < -threshold {
                                        // Swipe left - show delete
                                        dragOffset.width = -80
                                        isShowingActions = true
                                        
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            if dragOffset.width < 0 && isShowingActions {
                                                resetOffset()
                                            }
                                        }
                                    } else {
                                        resetOffset()
                                    }
                                } else {
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
    
}