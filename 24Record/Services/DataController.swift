import Foundation
import SwiftData
import SwiftUI

@MainActor
class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            SDTimeBlock.self,
            SDCategory.self,
            SDTag.self,
            SDTaskTemplate.self,
            SDRecurringTask.self,
            SDAppSettings.self,
            SDStatisticsCache.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Enable iCloud sync
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Setup default data if needed
            setupDefaultDataIfNeeded()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    private func setupDefaultDataIfNeeded() {
        let context = container.mainContext
        
        // Check if categories exist
        let descriptor = FetchDescriptor<SDCategory>()
        do {
            let categories = try context.fetch(descriptor)
            if categories.isEmpty {
                createDefaultCategories(in: context)
            }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
        
        // Check if app settings exist
        let settingsDescriptor = FetchDescriptor<SDAppSettings>()
        do {
            let settings = try context.fetch(settingsDescriptor)
            if settings.isEmpty {
                let defaultSettings = SDAppSettings()
                context.insert(defaultSettings)
            }
        } catch {
            print("Failed to fetch settings: \(error)")
        }
    }
    
    private func createDefaultCategories(in context: ModelContext) {
        let defaultCategories = [
            // 仕事・業務関連
            ("仕事", "FF6B9D", "briefcase.fill"),
            ("会議", "E91E63", "person.3.fill"),
            ("プロジェクト", "FF5722", "folder.fill"),
            ("メール・連絡", "FF9800", "envelope.fill"),
            
            // 個人・生活
            ("個人", "4ECDC4", "person.fill"),
            ("家事", "00BCD4", "house.fill"),
            ("買い物", "3F51B5", "cart.fill"),
            ("準備・身支度", "673AB7", "sparkles"),
            
            // 健康・ウェルネス
            ("睡眠", "45B7D1", "moon.fill"),
            ("運動", "96CEB4", "figure.run"),
            ("食事", "98D8C8", "fork.knife"),
            ("休憩", "81C784", "cup.and.saucer.fill"),
            
            // 学習・成長
            ("勉強", "FFEAA7", "book.fill"),
            ("読書", "FFC107", "book.closed.fill"),
            ("スキルアップ", "FF6F00", "star.fill"),
            
            // 娯楽・趣味
            ("娯楽", "DDA0DD", "gamecontroller.fill"),
            ("SNS・ネット", "9C27B0", "globe"),
            ("趣味", "BA68C8", "paintbrush.fill"),
            ("テレビ・動画", "7B1FA2", "tv.fill"),
            
            // 移動・外出
            ("通勤", "F7DC6F", "car.fill"),
            ("外出", "FFEB3B", "figure.walk"),
            
            // その他
            ("その他", "9E9E9E", "ellipsis.circle.fill")
        ]
        
        for (index, (name, color, icon)) in defaultCategories.enumerated() {
            let category = SDCategory(name: name, colorHex: color, icon: icon, order: index)
            context.insert(category)
        }
        
        do {
            try context.save()
            print("Default categories created successfully")
        } catch {
            print("Failed to save default categories: \(error)")
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults() async {
        let context = container.mainContext
        
        // Check if migration is needed
        let migrationKey = "hasCompletedSwiftDataMigration"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        
        await MainActor.run {
            do {
                // Migration is no longer needed since old models are removed
                // Simply mark migration as complete to avoid running this again
                
                // Save all migrations
                try context.save()
                
                // Mark migration as complete
                UserDefaults.standard.set(true, forKey: migrationKey)
                
            } catch {
                print("Migration failed: \(error)")
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func save() {
        do {
            try container.mainContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    @MainActor
    func delete<T: PersistentModel>(_ object: T) {
        container.mainContext.delete(object)
        save()
    }
    
    @MainActor
    func getAppSettings() -> SDAppSettings? {
        let descriptor = FetchDescriptor<SDAppSettings>()
        do {
            let settings = try container.mainContext.fetch(descriptor)
            return settings.first
        } catch {
            print("Failed to fetch app settings: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Reset
    
    @MainActor
    func resetAllData() {
        let context = container.mainContext
        
        do {
            // Delete all time blocks
            let timeBlockDescriptor = FetchDescriptor<SDTimeBlock>()
            let timeBlocks = try context.fetch(timeBlockDescriptor)
            for block in timeBlocks {
                context.delete(block)
            }
            
            // Delete all categories
            let categoryDescriptor = FetchDescriptor<SDCategory>()
            let categories = try context.fetch(categoryDescriptor)
            for category in categories {
                context.delete(category)
            }
            
            // Delete all tags
            let tagDescriptor = FetchDescriptor<SDTag>()
            let tags = try context.fetch(tagDescriptor)
            for tag in tags {
                context.delete(tag)
            }
            
            // Delete all task templates
            let templateDescriptor = FetchDescriptor<SDTaskTemplate>()
            let templates = try context.fetch(templateDescriptor)
            for template in templates {
                context.delete(template)
            }
            
            // Delete all recurring tasks
            let recurringDescriptor = FetchDescriptor<SDRecurringTask>()
            let recurringTasks = try context.fetch(recurringDescriptor)
            for task in recurringTasks {
                context.delete(task)
            }
            
            // Delete all app settings
            let settingsDescriptor = FetchDescriptor<SDAppSettings>()
            let settings = try context.fetch(settingsDescriptor)
            for setting in settings {
                context.delete(setting)
            }
            
            // Delete all statistics cache
            let statsDescriptor = FetchDescriptor<SDStatisticsCache>()
            let stats = try context.fetch(statsDescriptor)
            for stat in stats {
                context.delete(stat)
            }
            
            // Save changes
            try context.save()
            
            // Recreate default data
            setupDefaultDataIfNeeded()
            
            print("All data has been reset successfully")
            
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}