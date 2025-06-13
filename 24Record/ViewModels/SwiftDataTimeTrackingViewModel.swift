import Foundation
import SwiftUI
import SwiftData

@MainActor
class SwiftDataTimeTrackingViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var isTracking: Bool = false
    @Published var currentTrackingBlock: SDTimeBlock?
    @Published var trackingStartTime: Date?
    @Published var searchText: String = ""
    @Published var selectedTags: Set<SDTag> = []
    @Published var selectedPeriod: StatisticsPeriod = .daily
    @Published var refreshTrigger: UUID = UUID()
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // 今日の日付の開始時刻（0:00）に設定
        self.selectedDate = Calendar.current.startOfDay(for: Date())
    }
    
    // MARK: - Fetch Methods
    
    func getTimeBlocks(for date: Date) -> [SDTimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<SDTimeBlock> { block in
            block.startTime >= startOfDay && block.startTime < endOfDay
        }
        
        let descriptor = FetchDescriptor<SDTimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch time blocks: \(error)")
            return []
        }
    }
    
    func getAllTimeBlocks() -> [SDTimeBlock] {
        let descriptor = FetchDescriptor<SDTimeBlock>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch all time blocks: \(error)")
            return []
        }
    }
    
    func getFilteredTimeBlocks(searchText: String = "", tags: Set<SDTag> = [], dateRange: ClosedRange<Date>? = nil) -> [SDTimeBlock] {
        let descriptor = FetchDescriptor<SDTimeBlock>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            var blocks = try modelContext.fetch(descriptor)
            
            // Apply all filters manually
            if !searchText.isEmpty {
                blocks = blocks.filter { block in
                    block.title.localizedStandardContains(searchText) ||
                    block.notes.localizedStandardContains(searchText)
                }
            }
            
            if let range = dateRange {
                blocks = blocks.filter { block in
                    block.startTime >= range.lowerBound && block.startTime <= range.upperBound
                }
            }
            
            if !tags.isEmpty {
                blocks = blocks.filter { block in
                    !Set(block.tags).intersection(tags).isEmpty
                }
            }
            
            return blocks
        } catch {
            print("Failed to fetch filtered time blocks: \(error)")
            return []
        }
    }
    
    func getCategories() -> [SDCategory] {
        let descriptor = FetchDescriptor<SDCategory>(
            sortBy: [SortDescriptor(\.order)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func getTags() -> [SDTag] {
        let descriptor = FetchDescriptor<SDTag>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }
    
    func getTaskTemplates() -> [SDTaskTemplate] {
        let descriptor = FetchDescriptor<SDTaskTemplate>(
            sortBy: [SortDescriptor(\.order)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch task templates: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD Operations
    
    func addTimeBlock(title: String, startTime: Date, endTime: Date, category: SDCategory, notes: String = "", tags: [SDTag] = []) {
        let block = SDTimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            category: category,
            notes: notes,
            tags: tags
        )
        
        modelContext.insert(block)
        save()
        
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    func updateTimeBlock(_ block: SDTimeBlock, title: String? = nil, startTime: Date? = nil, endTime: Date? = nil, category: SDCategory? = nil, notes: String? = nil, tags: [SDTag]? = nil, isCompleted: Bool? = nil) {
        if let title = title { block.title = title }
        if let startTime = startTime { block.startTime = startTime }
        if let endTime = endTime { block.endTime = endTime }
        if let category = category { block.category = category }
        if let notes = notes { block.notes = notes }
        if let tags = tags { block.tags = tags }
        if let isCompleted = isCompleted { block.isCompleted = isCompleted }
        
        save()
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    func updateTimeBlock(_ block: SDTimeBlock) {
        // Simply save the block with its current state
        save()
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    func deleteTimeBlock(_ block: SDTimeBlock) {
        modelContext.delete(block)
        save()
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    func addCategory(name: String, colorHex: String, icon: String) {
        let categories = getCategories()
        let maxOrder = categories.map { $0.order }.max() ?? 0
        
        let category = SDCategory(
            name: name,
            colorHex: colorHex,
            icon: icon,
            order: maxOrder + 1
        )
        
        modelContext.insert(category)
        save()
    }
    
    func addTag(name: String, colorHex: String = "FF6B9D") {
        let tag = SDTag(name: name, colorHex: colorHex)
        modelContext.insert(tag)
        save()
    }
    
    func addTaskTemplate(name: String, title: String, duration: TimeInterval, category: SDCategory, notes: String = "", tags: [SDTag] = []) {
        let templates = getTaskTemplates()
        let maxOrder = templates.map { $0.order }.max() ?? 0
        
        let template = SDTaskTemplate(
            name: name,
            title: title,
            duration: duration,
            category: category,
            notes: notes,
            tags: tags,
            order: maxOrder + 1
        )
        
        modelContext.insert(template)
        save()
    }
    
    func createTaskFromTemplate(_ template: SDTaskTemplate, startTime: Date) {
        let endTime = startTime.addingTimeInterval(template.duration)
        
        addTimeBlock(
            title: template.title,
            startTime: startTime,
            endTime: endTime,
            category: template.category!,
            notes: template.notes,
            tags: template.tags
        )
    }
    
    // MARK: - Tracking Methods
    
    func startTracking(category: SDCategory, title: String) {
        trackingStartTime = Date()
        currentTrackingBlock = SDTimeBlock(
            title: title,
            startTime: Date(),
            endTime: Date(),
            category: category
        )
        isTracking = true
    }
    
    func stopTracking() {
        guard let block = currentTrackingBlock,
              let startTime = trackingStartTime else { return }
        
        let endTime = Date()
        
        addTimeBlock(
            title: block.title,
            startTime: startTime,
            endTime: endTime,
            category: block.category!,
            notes: block.notes,
            tags: block.tags
        )
        
        currentTrackingBlock = nil
        trackingStartTime = nil
        isTracking = false
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    // MARK: - Statistics Methods
    
    func getStatistics(for date: Date, period: StatisticsPeriod) -> [CategoryStatistics] {
        // Check cache first
        if let cachedStats = getCachedStatistics(for: date, period: period) {
            return cachedStats
        }
        
        // Calculate fresh statistics
        let blocks = getTimeBlocksForPeriod(date: date, period: period)
        var stats: [UUID: (category: SDCategory, totalTime: TimeInterval, taskCount: Int)] = [:]
        
        for block in blocks {
            guard let category = block.category else { continue }
            
            if let existing = stats[category.id] {
                stats[category.id] = (category, existing.totalTime + block.duration, existing.taskCount + 1)
            } else {
                stats[category.id] = (category, block.duration, 1)
            }
        }
        
        let categoryStats = stats.map { 
            CategoryStatistics(
                category: $0.value.category,
                totalTime: $0.value.totalTime
            )
        }.sorted { $0.totalTime > $1.totalTime }
        
        // Cache the results
        cacheStatistics(stats, for: date, period: period)
        
        return categoryStats
    }
    
    private func getTimeBlocksForPeriod(date: Date, period: StatisticsPeriod) -> [SDTimeBlock] {
        let calendar = Calendar.current
        var startDate: Date
        var endDate: Date
        
        switch period {
        case .daily:
            startDate = calendar.startOfDay(for: date)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            startDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: date)!
            startDate = calendar.startOfDay(for: startDate)
            endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        case .monthly:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        case .yearly:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: date))!
            endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        let predicate = #Predicate<SDTimeBlock> { block in
            block.startTime >= startDate && block.startTime < endDate
        }
        
        let descriptor = FetchDescriptor<SDTimeBlock>(predicate: predicate)
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch time blocks for period: \(error)")
            return []
        }
    }
    
    // MARK: - Cache Methods
    
    private func getCachedStatistics(for date: Date, period: StatisticsPeriod) -> [CategoryStatistics]? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Fetch all cache entries and filter manually
        let descriptor = FetchDescriptor<SDStatisticsCache>()
        
        do {
            let allCaches = try modelContext.fetch(descriptor)
            
            // Manual filtering
            let periodString = period.rawValue
            let caches = allCaches.filter { cache in
                cache.date == startOfDay && cache.period == periodString
            }
            
            // Check if cache is still valid (updated within last hour)
            let validCaches = caches.filter { cache in
                Date().timeIntervalSince(cache.lastUpdated) < 3600
            }
            
            if !validCaches.isEmpty {
                let categories = getCategories()
                return validCaches.compactMap { cache in
                    guard let category = categories.first(where: { $0.id == cache.categoryId }) else { return nil }
                    return CategoryStatistics(
                        category: category,
                        totalTime: cache.totalTime
                    )
                }.sorted { $0.totalTime > $1.totalTime }
            }
        } catch {
            print("Failed to fetch cached statistics: \(error)")
        }
        
        return nil
    }
    
    private func cacheStatistics(_ stats: [UUID: (category: SDCategory, totalTime: TimeInterval, taskCount: Int)], for date: Date, period: StatisticsPeriod) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Fetch all cache entries and filter manually
        let descriptor = FetchDescriptor<SDStatisticsCache>()
        
        do {
            let allCaches = try modelContext.fetch(descriptor)
            
            // Manual filtering and deletion
            let periodString = period.rawValue
            let oldCaches = allCaches.filter { cache in
                cache.date == startOfDay && cache.period == periodString
            }
            
            for cache in oldCaches {
                modelContext.delete(cache)
            }
            
            // Create new cache entries
            for (categoryId, data) in stats {
                let cache = SDStatisticsCache(
                    date: startOfDay,
                    period: period.rawValue,
                    categoryId: categoryId,
                    totalTime: data.totalTime,
                    taskCount: data.taskCount
                )
                modelContext.insert(cache)
            }
            
            save()
        } catch {
            print("Failed to cache statistics: \(error)")
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Premium Features Check
    
    func canAddTask(for date: Date) -> (allowed: Bool, reason: String?) {
        // Check if premium
        if StoreKitManager.isPremium {
            return (true, nil)
        }
        
        // Count tasks for the day
        let tasksToday = getTimeBlocks(for: date).count
        
        if tasksToday >= StoreKitManager.freeTaskLimit {
            return (false, "無料版では1日\(StoreKitManager.freeTaskLimit)タスクまでです")
        }
        
        return (true, nil)
    }
    
    func canAddTemplate() -> (allowed: Bool, reason: String?) {
        // Check if premium
        if StoreKitManager.isPremium {
            return (true, nil)
        }
        
        // Count templates
        let templateCount = getTaskTemplates().count
        
        if templateCount >= StoreKitManager.freeTemplateLimit {
            return (false, "無料版ではテンプレート\(StoreKitManager.freeTemplateLimit)個までです")
        }
        
        return (true, nil)
    }
    
    func canAccessDetailedStats() -> Bool {
        return StoreKitManager.isPremium
    }
    
    func canExportData() -> Bool {
        return StoreKitManager.isPremium
    }
    
    func canUseCustomThemes() -> Bool {
        return StoreKitManager.isPremium
    }
    
    func canUseAdvancedNotifications() -> Bool {
        return StoreKitManager.isPremium
    }
}