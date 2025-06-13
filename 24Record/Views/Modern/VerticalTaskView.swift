import SwiftUI
import SwiftData

struct VerticalTaskView: View {
    let block: SDTimeBlock
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @Binding var isReorderMode: Bool
    
    // Calculate height based on duration (1 hour = 80 points)
    private var taskHeight: CGFloat {
        let duration = block.endTime.timeIntervalSince(block.startTime)
        let hours = duration / 3600
        return max(30, hours * 80) // Minimum height of 30
    }
    
    private var durationText: String {
        let duration = Int(block.endTime.timeIntervalSince(block.startTime) / 60)
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
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Vertical task bar
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: block.category?.colorHex ?? "FF6B9D") ?? .pink,
                            (Color(hex: block.category?.colorHex ?? "FF6B9D") ?? .pink).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: taskHeight)
                .overlay(
                    // Category icon
                    VStack {
                        Image(systemName: block.category?.icon ?? "circle")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        Spacer()
                        
                        // Duration at bottom
                        Text(durationText)
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 8)
                    }
                )
                .shadow(color: (Color(hex: block.category?.colorHex ?? "FF6B9D") ?? .pink).opacity(0.3), radius: 6, x: 0, y: 3)
            
            // Text information on the side
            VStack(alignment: .leading, spacing: 4) {
                // Time range
                Text(timeRangeText)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                // Task title/category name
                Text(block.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Notes if available
                if !block.notes.isEmpty {
                    Text(block.notes)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(2)
                }
                
                // Status indicator
                if block.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(.caption2))
                        Text("完了")
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
            }
            .padding(.top, 4)
            
            Spacer()
            
            // Reorder handle (only visible in reorder mode)
            if isReorderMode {
                VStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}