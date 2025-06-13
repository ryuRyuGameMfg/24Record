import SwiftUI
import SwiftData

struct ImprovedOverlappingTasksView: View {
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
            
            // Overlapping tasks container with vertical layout
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(group.blocks.enumerated()), id: \.element.id) { index, block in
                        VStack(spacing: 4) {
                            // Overlap number indicator
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
                            .padding(.horizontal, 8)
                            
                            // Vertical task view
                            VerticalTaskView(
                                block: block,
                                viewModel: viewModel,
                                isReorderMode: .constant(false)
                            )
                            .frame(width: 250) // Fixed width for horizontal scroll
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: calculateGroupHeight())
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
            return max(40, CGFloat(duration / 3600) * 80) + 40 // hourHeight + padding
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
}