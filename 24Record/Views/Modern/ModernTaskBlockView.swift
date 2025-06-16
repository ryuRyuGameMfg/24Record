import SwiftUI
import UIKit

struct ModernTaskBlockView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var showingEdit = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var isHovered = false
    @FocusState private var isTitleFieldFocused: Bool
    
    var body: some View {
        Button(action: { 
            if !isEditing {
                showingEdit = true
            }
        }) {
            HStack(spacing: 16) {
                // Left side: Category indicator with icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [block.color, block.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: block.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: block.category?.icon ?? "circle")
                        .font(.system(.body))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Middle: Task content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    if isEditing {
                        TextField("タイトル", text: $editingTitle)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isTitleFieldFocused)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.pink.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .onSubmit {
                                saveTitle()
                            }
                    } else {
                        Text(block.title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        // Time info
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(timeText)
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundColor(.gray)
                        
                        // Duration
                        Text(durationText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.05))
                            )
                        
                        // Routine badge
                        if block.isRoutine {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                                Text("毎日")
                                    .font(.system(size: 11, design: .rounded))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(block.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(block.color.opacity(0.15))
                            )
                        }
                    }
                    
                    // Notes preview
                    if !block.notes.isEmpty {
                        Text(block.notes)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right: Actions
                VStack(spacing: 12) {
                    // Edit button (appears on hover)
                    if isHovered {
                        Button(action: {
                            startEditingTitle()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(.caption))
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Completion checkbox
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            block.isCompleted.toggle()
                            viewModel.updateTimeBlock(block)
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    block.isCompleted ? Color.green : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(block.isCompleted ? Color.green : Color.clear)
                                )
                            
                            if block.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: block.isCompleted ? 0.12 : 0.10),
                                Color(white: block.isCompleted ? 0.08 : 0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                block.isCompleted ? 
                                    Color.green.opacity(0.3) : 
                                    Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: block.isCompleted ? 
                    Color.green.opacity(0.2) : 
                    Color.black.opacity(0.2),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
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
            viewModel.updateTimeBlock(block)
            
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
                return "\(hours)時間\(minutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(duration)分"
        }
    }
    
    // 時間長さによる視覚的な強調表示
    private var durationIndicatorColor: Color {
        let durationMinutes = block.duration / 60
        switch durationMinutes {
        case 0..<15:
            return .yellow.opacity(0.8) // 短時間タスク
        case 15..<30:
            return .green.opacity(0.8) // 標準タスク
        case 30..<60:
            return .blue.opacity(0.8) // 中時間タスク
        case 60..<120:
            return .purple.opacity(0.8) // 長時間タスク
        default:
            return .red.opacity(0.8) // 超長時間タスク
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