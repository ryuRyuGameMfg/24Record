import Foundation

struct Utils {
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    static func formatTime(_ date: Date) -> String {
        DateFormatter.japaneseTime.string(from: date)
    }
    
    static func formatDate(_ date: Date) -> String {
        DateFormatter.japaneseDate.string(from: date)
    }
    
    static func formatMonthDay(_ date: Date) -> String {
        DateFormatter.japaneseMonthDay.string(from: date)
    }
    
    static func formatMonthYear(_ date: Date) -> String {
        DateFormatter.japaneseMonthYear.string(from: date)
    }
    
    static func formatWeekday(_ date: Date) -> String {
        DateFormatter.japaneseWeekday.string(from: date)
    }
    
    static func formatWeekdayShort(_ date: Date) -> String {
        DateFormatter.japaneseWeekdayShort.string(from: date)
    }
}