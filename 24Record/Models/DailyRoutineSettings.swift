import Foundation
import SwiftUI

// 毎日の固定ルーティン設定
@MainActor
class DailyRoutineSettings: ObservableObject {
    static let shared = DailyRoutineSettings()
    
    @Published var wakeUpTime: Date {
        didSet {
            saveSettings()
        }
    }
    
    @Published var bedTime: Date {
        didSet {
            saveSettings()
        }
    }
    
    @Published var isRoutineEnabled: Bool {
        didSet {
            saveSettings()
        }
    }
    
    @Published var wakeUpCategory: String {
        didSet {
            saveSettings()
        }
    }
    
    @Published var bedTimeCategory: String {
        didSet {
            saveSettings()
        }
    }
    
    private init() {
        // デフォルト値を設定
        let calendar = Calendar.current
        let now = Date()
        
        // デフォルト起床時間: 7:00
        var wakeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        wakeComponents.hour = 7
        wakeComponents.minute = 0
        let defaultWakeTime = calendar.date(from: wakeComponents) ?? now
        
        // デフォルト就寝時間: 23:00
        var bedComponents = calendar.dateComponents([.year, .month, .day], from: now)
        bedComponents.hour = 23
        bedComponents.minute = 0
        let defaultBedTime = calendar.date(from: bedComponents) ?? now
        
        // UserDefaultsから読み込み
        if let wakeTimeInterval = UserDefaults.standard.object(forKey: "wakeUpTime") as? TimeInterval {
            self.wakeUpTime = Date(timeIntervalSinceReferenceDate: wakeTimeInterval)
        } else {
            self.wakeUpTime = defaultWakeTime
        }
        
        if let bedTimeInterval = UserDefaults.standard.object(forKey: "bedTime") as? TimeInterval {
            self.bedTime = Date(timeIntervalSinceReferenceDate: bedTimeInterval)
        } else {
            self.bedTime = defaultBedTime
        }
        
        self.isRoutineEnabled = UserDefaults.standard.bool(forKey: "isRoutineEnabled")
        if UserDefaults.standard.object(forKey: "isRoutineEnabled") == nil {
            self.isRoutineEnabled = true // デフォルトで有効
        }
        
        self.wakeUpCategory = UserDefaults.standard.string(forKey: "wakeUpCategory") ?? "個人"
        self.bedTimeCategory = UserDefaults.standard.string(forKey: "bedTimeCategory") ?? "睡眠"
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(wakeUpTime.timeIntervalSinceReferenceDate, forKey: "wakeUpTime")
        UserDefaults.standard.set(bedTime.timeIntervalSinceReferenceDate, forKey: "bedTime")
        UserDefaults.standard.set(isRoutineEnabled, forKey: "isRoutineEnabled")
        UserDefaults.standard.set(wakeUpCategory, forKey: "wakeUpCategory")
        UserDefaults.standard.set(bedTimeCategory, forKey: "bedTimeCategory")
    }
    
    // 指定された日付の起床時間を取得
    func getWakeUpTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = wakeComponents.hour
        dateComponents.minute = wakeComponents.minute
        
        return calendar.date(from: dateComponents) ?? date
    }
    
    // 指定された日付の就寝時間を取得
    func getBedTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = bedComponents.hour
        dateComponents.minute = bedComponents.minute
        
        return calendar.date(from: dateComponents) ?? date
    }
    
    // 固定ルーティンタスクを生成
    func generateRoutineTasks(for date: Date) -> [(title: String, startTime: Date, endTime: Date, categoryName: String)] {
        guard isRoutineEnabled else { return [] }
        
        var tasks: [(title: String, startTime: Date, endTime: Date, categoryName: String)] = []
        
        let wakeTime = getWakeUpTime(for: date)
        let sleepTime = getBedTime(for: date)
        
        // 起床タスク
        tasks.append((
            title: "起床",
            startTime: wakeTime,
            endTime: wakeTime.addingTimeInterval(300), // 5分
            categoryName: wakeUpCategory
        ))
        
        // 就寝タスク
        tasks.append((
            title: "就寝",
            startTime: sleepTime,
            endTime: sleepTime.addingTimeInterval(28800), // 8時間（翌朝まで）
            categoryName: bedTimeCategory
        ))
        
        return tasks
    }
}