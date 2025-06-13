import Foundation
import SwiftData
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - SwiftData Models

@Model
final class SDTimeBlock {
    var id: UUID = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var isCompleted: Bool
    
    @Relationship(deleteRule: .nullify) var category: SDCategory?
    @Relationship(deleteRule: .cascade) var tags: [SDTag]
    
    @Transient var isRoutine: Bool = false
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var color: Color {
        category?.color ?? Color.gray
    }
    
    init(title: String, startTime: Date, endTime: Date, category: SDCategory? = nil, notes: String = "", isCompleted: Bool = false, tags: [SDTag] = []) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.notes = notes
        self.isCompleted = isCompleted
        self.tags = tags
    }
}

@Model
final class SDCategory {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var icon: String
    var order: Int
    
    @Relationship(deleteRule: .nullify, inverse: \SDTimeBlock.category) 
    var timeBlocks: [SDTimeBlock]
    
    var color: Color {
        Color(colorHex)
    }
    
    init(name: String, colorHex: String, icon: String, order: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.order = order
        self.timeBlocks = []
    }
}

@Model
final class SDTag {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    
    @Relationship(deleteRule: .nullify, inverse: \SDTimeBlock.tags)
    var timeBlocks: [SDTimeBlock]
    
    var color: Color {
        Color(colorHex)
    }
    
    init(name: String, colorHex: String = "FF6B9D") {
        self.name = name
        self.colorHex = colorHex
        self.timeBlocks = []
    }
}

@Model
final class SDTaskTemplate {
    var id: UUID = UUID()
    var name: String
    var title: String
    var duration: TimeInterval
    var notes: String
    var order: Int
    
    @Relationship(deleteRule: .nullify) var category: SDCategory?
    @Relationship(deleteRule: .cascade) var tags: [SDTag]
    
    init(name: String, title: String, duration: TimeInterval, category: SDCategory? = nil, notes: String = "", tags: [SDTag] = [], order: Int = 0) {
        self.name = name
        self.title = title
        self.duration = duration
        self.category = category
        self.notes = notes
        self.tags = tags
        self.order = order
    }
}

@Model
final class SDRecurringTask {
    var id: UUID = UUID()
    var title: String
    var duration: TimeInterval
    var recurrenceRule: String
    var isActive: Bool
    var defaultStartTime: Date
    
    @Relationship(deleteRule: .nullify) var category: SDCategory?
    
    init(title: String, category: SDCategory?, duration: TimeInterval, recurrenceRule: String, defaultStartTime: Date, isActive: Bool = true) {
        self.title = title
        self.category = category
        self.duration = duration
        self.recurrenceRule = recurrenceRule
        self.defaultStartTime = defaultStartTime
        self.isActive = isActive
    }
}


// MARK: - App Settings Model

@Model
final class SDAppSettings {
    var id: UUID = UUID()
    var theme: String // "system", "light", "dark"
    var accentColorHex: String
    var useHaptics: Bool
    var useFaceID: Bool
    var privacyMode: Bool
    var hiddenCategoryIds: [UUID]
    
    init(theme: String = "system", accentColorHex: String = "FF6B9D", useHaptics: Bool = true, useFaceID: Bool = false, privacyMode: Bool = false, hiddenCategoryIds: [UUID] = []) {
        self.theme = theme
        self.accentColorHex = accentColorHex
        self.useHaptics = useHaptics
        self.useFaceID = useFaceID
        self.privacyMode = privacyMode
        self.hiddenCategoryIds = hiddenCategoryIds
    }
}

// MARK: - Statistics Cache Model

@Model
final class SDStatisticsCache {
    var id: UUID = UUID()
    var date: Date
    var period: String // "daily", "weekly", "monthly"
    var categoryId: UUID
    var totalTime: TimeInterval
    var taskCount: Int
    var lastUpdated: Date
    
    init(date: Date, period: String, categoryId: UUID, totalTime: TimeInterval, taskCount: Int) {
        self.date = date
        self.period = period
        self.categoryId = categoryId
        self.totalTime = totalTime
        self.taskCount = taskCount
        self.lastUpdated = Date()
    }
}