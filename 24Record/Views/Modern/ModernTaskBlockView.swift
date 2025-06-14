import SwiftUI

struct ModernTaskBlockView: View {
    let block: SDTimeBlock
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime) - \(endTime)"
    }
    
    private var durationText: String {
        let duration = block.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)時間\(minutes)分" : "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }
    
    private var progressPercentage: Double {
        let now = Date()
        if now < block.startTime {
            return 0
        } else if now > block.endTime {
            return 1
        } else {
            let elapsed = now.timeIntervalSince(block.startTime)
            return elapsed / block.duration
        }
    }
    
    private var isCurrentTask: Bool {
        let now = Date()
        return now >= block.startTime && now <= block.endTime
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Category color bar
            RoundedRectangle(cornerRadius: 8)
                .fill(block.category.color)
                .frame(width: 4)
                .padding(.vertical, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title and duration
                HStack {
                    Text(block.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(durationText)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
                
                // Time range and category
                HStack(spacing: 12) {
                    Label(timeRangeText, systemImage: "clock")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    if !block.category.name.isEmpty {
                        Text(block.category.name)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(block.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(block.category.color.opacity(0.2))
                            )
                    }
                    
                    Spacer()
                }
                
                // Progress bar for current task
                if isCurrentTask {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    colors: [block.category.color, block.category.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * progressPercentage, height: 4)
                                .animation(.linear(duration: 1), value: progressPercentage)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 12)
            .padding(.trailing, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isCurrentTask ? block.category.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            // Current task indicator
            isCurrentTask ?
            HStack {
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.5)
                            .opacity(0.3)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isCurrentTask
                            )
                    )
                    .padding(.trailing, 12)
            }
            .padding(.top, 12)
            : nil
        )
    }
}