import SwiftUI

struct TaskFocusedBlockView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var showingEdit = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task content
            HStack(spacing: 12) {
                // Category indicator (smaller, less prominent)
                Circle()
                    .fill(block.color.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 4)
                
                // Task content (primary focus)
                VStack(alignment: .leading, spacing: 4) {
                    // Task title - prominent
                    Text(block.title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // Task details when expanded
                    if isExpanded {
                        if !block.notes.isEmpty {
                            Text(block.notes)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray.opacity(0.9))
                                .padding(.top, 4)
                        }
                        
                        // Category name
                        HStack(spacing: 6) {
                            Image(systemName: block.category?.icon ?? "folder")
                                .font(.system(.caption))
                            Text(block.category?.name ?? "")
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundColor(block.color.opacity(0.8))
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Right side actions
                VStack(alignment: .trailing, spacing: 8) {
                    // Completion status
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            block.isCompleted.toggle()
                            viewModel.updateTimeBlock(block)
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(.title3))
                            .foregroundColor(block.isCompleted ? .green : .gray.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Duration badge (subtle)
                    Text(durationText)
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(taskBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
            
            // Time information (subtle, only when needed)
            if isExpanded || showsTimeContext {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(.caption2))
                    Text(timeRangeText)
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
        }
        .overlay(
            // Edit button (appears on hover/tap)
            HStack {
                Spacer()
                Button(action: {
                    showingEdit = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(.caption))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .opacity(isExpanded ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.trailing, 8)
            .padding(.top, 8),
            alignment: .topTrailing
        )
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
    
    private var taskBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                block.isCompleted ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    private var durationText: String {
        let duration = Int(block.duration / 60)
        if duration < 60 {
            return "\(duration)分"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes > 0 {
                return "\(hours)h\(minutes)m"
            } else {
                return "\(hours)時間"
            }
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let start = formatter.string(from: block.startTime)
        let end = formatter.string(from: block.endTime)
        
        return "\(start) - \(end)"
    }
    
    private var showsTimeContext: Bool {
        // Show time for first task of the day or when there's a significant gap
        false // Will be determined by parent view
    }
}