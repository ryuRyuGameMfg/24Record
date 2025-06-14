import SwiftUI

struct ImprovedTaskBlockView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var showingEdit = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var isHoveringTitle = false
    @State private var isHoveringTime = false
    @State private var isHoveringStatus = false
    @State private var showEditHint = false
    @FocusState private var isTitleFieldFocused: Bool
    
    // Task height calculation
    private var taskHeight: CGFloat {
        let durationMinutes = block.duration / 60
        let baseHeight: CGFloat = 60
        let minimumHeight: CGFloat = 50
        let maximumHeight: CGFloat = 100
        
        let proportionalHeight = (durationMinutes / 15.0) * baseHeight
        
        var adjustedHeight: CGFloat
        if durationMinutes < 10 {
            adjustedHeight = max(minimumHeight, proportionalHeight * 0.9)
        } else if durationMinutes < 15 {
            adjustedHeight = max(minimumHeight, proportionalHeight * 0.95)
        } else if durationMinutes < 30 {
            adjustedHeight = proportionalHeight
        } else if durationMinutes < 60 {
            adjustedHeight = proportionalHeight * 1.05
        } else if durationMinutes < 120 {
            adjustedHeight = proportionalHeight * 1.1
        } else {
            adjustedHeight = proportionalHeight * 1.15
        }
        
        return min(maximumHeight, adjustedHeight)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            categoryIcon
            taskInfo
            statusIndicator
        }
        .padding(.horizontal, 14)
        .padding(.vertical, taskHeight > 70 ? 14 : 10)
        .frame(minHeight: taskHeight)
        .background(taskBackground)
        .shadow(color: block.color.opacity(0.2), radius: 6, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
        .scaleEffect((showingEdit || isEditing) ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingEdit)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)
        .sheet(isPresented: $showingEdit) {
            UnifiedTaskAddView(
                viewModel: viewModel,
                isPresented: $showingEdit,
                existingBlock: block,
                onSave: { _ in },
                onDelete: {
                    viewModel.deleteTimeBlock(block)
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var categoryIcon: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [block.color, block.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: block.isRoutine ? "clock.badge.checkmark.fill" : (block.category?.icon ?? "circle"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .shadow(color: block.color.opacity(0.4), radius: 6, x: 0, y: 3)
            .scaleEffect(showingEdit ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingEdit)
            
            Spacer(minLength: 0)
        }
    }
    
    private var taskInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    timeDisplay
                    titleDisplay
                }
                Spacer()
            }
            
            Spacer(minLength: 0)
            
            if !block.notes.isEmpty {
                Text(block.notes)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            }
        }
    }
    
    private var timeDisplay: some View {
        HStack(spacing: 4) {
            Text(timeText)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(isHoveringTime ? .pink : .gray)
                .scaleEffect(isHoveringTime ? 1.05 : 1.0)
            
            if isHoveringTime {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(.caption2))
                    .foregroundColor(.pink.opacity(0.8))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHoveringTime ? Color.pink.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringTime = hovering
            }
        }
        .onTapGesture {
            showingEdit = true
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private var titleDisplay: some View {
        Group {
            if isEditing {
                TextField("タイトル", text: $editingTitle)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isTitleFieldFocused)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.pink.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.pink.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .onSubmit {
                        saveTitle()
                    }
            } else {
                titleWithHover
            }
        }
    }
    
    private var titleWithHover: some View {
        HStack(spacing: 4) {
            Text(block.title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            if isHoveringTitle && !showEditHint {
                Image(systemName: "pencil")
                    .font(.system(.caption))
                    .foregroundColor(.gray)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHoveringTitle ? Color.white.opacity(0.05) : Color.clear)
        )
        .overlay(editHintOverlay)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringTitle = hovering
                if hovering && !showEditHint {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if isHoveringTitle {
                            withAnimation {
                                showEditHint = true
                            }
                        }
                    }
                } else {
                    showEditHint = false
                }
            }
        }
        .onTapGesture {
            startEditingTitle()
        }
    }
    
    private var editHintOverlay: some View {
        Group {
            if showEditHint {
                Text("タップして編集")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.pink))
                    .offset(y: -30)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var statusIndicator: some View {
        VStack {
            Button(action: toggleCompletion) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isHoveringStatus ? statusColor.opacity(0.8) : statusColor.opacity(0.6),
                            lineWidth: isHoveringStatus ? 3 : 2
                        )
                        .background(
                            Circle()
                                .fill(block.isCompleted ? statusColor : Color.clear)
                                .animation(.easeInOut(duration: 0.2), value: block.isCompleted)
                        )
                        .frame(width: 24, height: 24)
                        .scaleEffect(isHoveringStatus ? 1.2 : 1.0)
                    
                    if block.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringStatus = hovering
                }
            }
            
            Spacer()
        }
    }
    
    private var taskBackground: some View {
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
            .overlay(editModeIndicator)
    }
    
    private var editModeIndicator: some View {
        Group {
            if showingEdit || isEditing {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.pink.opacity(0.6), lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: showingEdit)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
    
    private var statusColor: Color {
        block.isCompleted ? .teal : .pink
    }
    
    // MARK: - Actions
    
    private func startEditingTitle() {
        editingTitle = block.title
        isEditing = true
        showEditHint = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTitleFieldFocused = true
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveTitle() {
        if !editingTitle.isEmpty && editingTitle != block.title {
            block.title = editingTitle
            viewModel.updateTimeBlock(block)
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        isEditing = false
        isTitleFieldFocused = false
    }
    
    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            block.isCompleted.toggle()
            viewModel.updateTimeBlock(block)
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}