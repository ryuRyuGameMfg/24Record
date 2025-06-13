import Foundation
import SwiftData

// MARK: - Supporting Types
enum StatisticsPeriod: String {
    case daily = "daily"
    case weekly = "weekly"  
    case monthly = "monthly"
    case yearly = "yearly"
}

struct CategoryStatistics: Identifiable {
    let category: SDCategory
    let totalTime: TimeInterval
    
    var id: UUID {
        category.id
    }
}

struct EmptyTimeSlot: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}