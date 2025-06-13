import SwiftUI
import SwiftData

// MARK: - Preview Container
struct PreviewContainer<Content: View>: View {
    let content: () -> Content
    @State private var container: ModelContainer
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        do {
            let schema = Schema([
                SDTimeBlock.self,
                SDCategory.self,
                SDTag.self,
                SDTaskTemplate.self,
                SDRecurringTask.self,
                SDAppSettings.self,
                SDStatisticsCache.self
            ])
            
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            _container = State(initialValue: container)
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    var body: some View {
        content()
            .modelContainer(container)
            .environment(\.locale, Locale(identifier: "ja_JP"))
    }
}

// MARK: - Preview Data
extension ModelContext {
    func createPreviewData() {
        // Create categories
        let categories = [
            SDCategory(name: "仕事", colorHex: "FF6B9D", icon: "briefcase.fill", order: 0),
            SDCategory(name: "個人", colorHex: "4ECDC4", icon: "person.fill", order: 1),
            SDCategory(name: "睡眠", colorHex: "45B7D1", icon: "moon.fill", order: 2),
            SDCategory(name: "運動", colorHex: "96CEB4", icon: "figure.run", order: 3),
            SDCategory(name: "勉強", colorHex: "FFEAA7", icon: "book.fill", order: 4),
            SDCategory(name: "娯楽", colorHex: "DDA0DD", icon: "gamecontroller.fill", order: 5),
            SDCategory(name: "食事", colorHex: "98D8C8", icon: "fork.knife", order: 6),
            SDCategory(name: "通勤", colorHex: "F7DC6F", icon: "car.fill", order: 7)
        ]
        
        categories.forEach { insert($0) }
        
        // Create tags
        let tags = [
            SDTag(name: "重要", colorHex: "FF0000"),
            SDTag(name: "緊急", colorHex: "FFA500"),
            SDTag(name: "定期", colorHex: "0000FF")
        ]
        
        tags.forEach { insert($0) }
        
        // Create sample time blocks
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let timeBlocks = [
            SDTimeBlock(
                title: "朝の準備",
                startTime: calendar.date(byAdding: .hour, value: 7, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 8, to: startOfDay)!,
                category: categories[1],
                notes: "シャワー、朝食、身支度"
            ),
            SDTimeBlock(
                title: "通勤",
                startTime: calendar.date(byAdding: .hour, value: 8, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
                category: categories[7]
            ),
            SDTimeBlock(
                title: "メールチェック",
                startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
                endTime: calendar.date(byAdding: .minute, value: 570, to: startOfDay)!,
                category: categories[0],
                notes: "優先度の高いメールから処理"
            ),
            SDTimeBlock(
                title: "プロジェクト作業",
                startTime: calendar.date(byAdding: .minute, value: 570, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
                category: categories[0],
                notes: "機能実装とコードレビュー"
            ),
            SDTimeBlock(
                title: "昼食",
                startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!,
                category: categories[6]
            ),
            SDTimeBlock(
                title: "会議",
                startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!,
                category: categories[0],
                notes: "週次チームミーティング"
            ),
            SDTimeBlock(
                title: "運動",
                startTime: calendar.date(byAdding: .hour, value: 18, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: 19, to: startOfDay)!,
                category: categories[3],
                notes: "ジムでトレーニング"
            )
        ]
        
        timeBlocks.forEach { insert($0) }
        
        // Create templates
        let templates = [
            SDTaskTemplate(
                name: "朝のルーティン",
                title: "朝の準備",
                duration: 3600,
                category: categories[1],
                notes: "シャワー、朝食、身支度"
            ),
            SDTaskTemplate(
                name: "定例会議",
                title: "週次ミーティング",
                duration: 3600,
                category: categories[0],
                notes: "チーム全体での進捗共有"
            )
        ]
        
        templates.forEach { insert($0) }
        
        // Create app settings
        let settings = SDAppSettings()
        insert(settings)
        
        try? save()
    }
}

// MARK: - Preview ViewModel
extension SwiftDataTimeTrackingViewModel {
    static func preview(in context: ModelContext) -> SwiftDataTimeTrackingViewModel {
        let viewModel = SwiftDataTimeTrackingViewModel(modelContext: context)
        return viewModel
    }
}