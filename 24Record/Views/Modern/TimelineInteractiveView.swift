import SwiftUI

struct TimelineInteractiveView: View {
    let hour: Int
    let selectedDate: Date
    let existingBlocks: [SDTimeBlock]
    let onTapTime: (Date) -> Void
    
    @State private var tapLocation: CGPoint = .zero
    @State private var showTimeIndicator = false
    @State private var hoveredMinute: Int? = nil
    
    private let hourHeight: CGFloat = 80
    private let minuteIndicatorHeight: CGFloat = 1.33 // hourHeight / 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Interactive background for each hour
                ForEach(0..<60, id: \.self) { minute in
                    let hasTask = hasTaskAtMinute(minute)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: minuteIndicatorHeight)
                        .offset(y: CGFloat(minute) * minuteIndicatorHeight)
                        .overlay(
                            // Visual feedback on hover
                            Group {
                                if hoveredMinute == minute && !hasTask {
                                    Rectangle()
                                        .fill(Color.pink.opacity(0.2))
                                        .frame(height: minuteIndicatorHeight * 5) // 5 minute block
                                        .overlay(
                                            HStack {
                                                Text(formatTime(hour: hour, minute: minute))
                                                    .font(.system(.caption2, design: .rounded))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.pink)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.black.opacity(0.8))
                                                            .overlay(
                                                                Capsule()
                                                                    .strokeBorder(Color.pink.opacity(0.5), lineWidth: 1)
                                                            )
                                                    )
                                                Spacer()
                                            }
                                            .padding(.leading, 4)
                                        )
                                }
                            }
                        )
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering && !hasTask {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredMinute = minute
                                }
                            } else if hoveredMinute == minute {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredMinute = nil
                                }
                            }
                        }
                        .onTapGesture {
                            if !hasTask {
                                let tappedTime = createTime(hour: hour, minute: minute)
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                onTapTime(tappedTime)
                            }
                        }
                }
                
                // Visual guide lines every 15 minutes
                ForEach([0, 15, 30, 45], id: \.self) { minute in
                    if !hasTaskAtMinute(minute) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 0.5)
                            .offset(y: CGFloat(minute) * minuteIndicatorHeight)
                    }
                }
            }
            .frame(height: hourHeight)
        }
    }
    
    private func hasTaskAtMinute(_ minute: Int) -> Bool {
        let calendar = Calendar.current
        let checkTime = createTime(hour: hour, minute: minute)
        
        return existingBlocks.contains { block in
            // Check if this minute falls within any task
            return checkTime >= block.startTime && checkTime < block.endTime
        }
    }
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents) ?? selectedDate
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// Visual time selection preview
struct TimeSelectionPreview: View {
    let time: Date
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.pink)
            
            Text(timeText)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.pink.opacity(0.9))
                .shadow(color: Color.pink.opacity(0.5), radius: 6, x: 0, y: 2)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
}