import SwiftUI

struct DurationQuickSelector: View {
    @Binding var selectedDuration: TimeInterval
    let onDurationChanged: (TimeInterval) -> Void
    
    private let durations: [(String, TimeInterval)] = [
        ("15m", 900),
        ("30m", 1800),
        ("45m", 2700),
        ("1h", 3600),
        ("2h", 7200),
        ("3h", 10800)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack(spacing: 8) {
                ForEach(durations, id: \.1) { label, duration in
                    Button(action: {
                        selectedDuration = duration
                        onDurationChanged(duration)
                    }) {
                        Text(label)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(selectedDuration == duration ? .semibold : .regular)
                            .foregroundColor(selectedDuration == duration ? .white : .gray)
                            .frame(minWidth: 44, maxWidth: 60)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedDuration == duration ? 
                                          LinearGradient(
                                              colors: [.pink, .red],
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          ) : 
                                          LinearGradient(
                                              colors: [Color(white: 0.12), Color(white: 0.08)],
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                selectedDuration == duration ? Color.clear : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: selectedDuration == duration ? Color.pink.opacity(0.3) : Color.clear, 
                                   radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(selectedDuration == duration ? 1.05 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedDuration == duration)
                }
            }
        }
    }
}

// Preview
#Preview {
    DurationQuickSelector(
        selectedDuration: .constant(3600),
        onDurationChanged: { _ in }
    )
    .padding()
    .background(Color.black)
}