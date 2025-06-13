import Foundation

// 日本語ローカライゼーション
struct L10n {
    // MARK: - Common
    static let cancel = "キャンセル"
    static let save = "保存"
    static let delete = "削除"
    static let edit = "編集"
    static let done = "完了"
    static let add = "追加"
    static let close = "閉じる"
    static let ok = "OK"
    static let none = "なし"
    
    // MARK: - Task
    static let task = "タスク"
    static let taskTitle = "タスク名"
    static let taskDetails = "タスクの詳細"
    static let addTask = "タスクを追加"
    static let editTask = "タスクを編集"
    static let deleteTask = "タスクを削除"
    static let quickAdd = "クイック追加"
    static let detailed = "詳細"
    static let whatAreYouDoing = "何をしていますか？"
    
    // MARK: - Time
    static let startTime = "開始時間"
    static let endTime = "終了時間"
    static let duration = "時間"
    static let adjustTime = "時間を調整"
    static let quickAdjust = "クイック調整"
    static let both = "両方"
    static let start = "開始"
    static let end = "終了"
    
    // MARK: - Category
    static let category = "カテゴリー"
    static let categories = "カテゴリー"
    static let selectCategory = "カテゴリーを選択"
    
    // MARK: - Notes
    static let notes = "メモ"
    static let additionalInfo = "追加情報"
    
    // MARK: - Statistics
    static let statistics = "統計"
    static let analytics = "分析"
    static let daily = "日別"
    static let weekly = "週別"
    static let monthly = "月別"
    static let yearly = "年別"
    static let breakdown = "内訳"
    static let timeByCategory = "カテゴリー別時間"
    static let noDataForPeriod = "この期間のデータはありません"
    static let categoryStatistics = "カテゴリ別統計"
    
    // MARK: - Analytics
    static let totalTime = "総時間"
    static let taskCount = "タスク数"
    static let averageSession = "平均セッション"
    static let completionRate = "完了率"
    static let timeDistribution = "時間配分"
    static let categoryByTime = "カテゴリー別時間"
    static let timeTrend = "時間の推移"
    static let hourlyActivity = "時間別活動"
    static let detailedStatistics = "詳細統計"
    static let noDataAvailable = "データがありません"
    static let noTasksInPeriod = "選択した期間にタスクがありません"
    static let mostProductiveHour = "最も生産的な時間"
    static let tasks = "タスク"
    
    // MARK: - Timeline
    static let timeline = "タイムライン"
    static let today = "今日"
    static let yesterday = "昨日"
    static let tomorrow = "明日"
    
    // MARK: - Settings
    static let settings = "設定"
    static let theme = "テーマ"
    static let accentColor = "アクセントカラー"
    static let haptics = "触覚フィードバック"
    static let faceID = "Face ID"
    static let privacyMode = "プライバシーモード"
    
    // MARK: - AI Suggestions
    static let morningWorkSession = "朝の作業時間"
    static let teamMeeting = "チームミーティング"
    static let eveningRoutine = "夜のルーティン"
    
    // MARK: - Days of Week
    static let sunday = "日曜日"
    static let monday = "月曜日"  
    static let tuesday = "火曜日"
    static let wednesday = "水曜日"
    static let thursday = "木曜日"
    static let friday = "金曜日"
    static let saturday = "土曜日"
    
    static let sundayShort = "日"
    static let mondayShort = "月"
    static let tuesdayShort = "火"
    static let wednesdayShort = "水"
    static let thursdayShort = "木"
    static let fridayShort = "金"
    static let saturdayShort = "土"
    
    // MARK: - Months
    static let january = "1月"
    static let february = "2月"
    static let march = "3月"
    static let april = "4月"
    static let may = "5月"
    static let june = "6月"
    static let july = "7月"
    static let august = "8月"
    static let september = "9月"
    static let october = "10月"
    static let november = "11月"
    static let december = "12月"
}

// Date Formatter Extensions
extension DateFormatter {
    static let japanese: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
    
    static let japaneseTime: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let japaneseDate: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let japaneseFull: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let japaneseMonthDay: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    static let japaneseMonthYear: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
    
    static let japaneseWeekday: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let japaneseWeekdayShort: DateFormatter = {
        let formatter = DateFormatter.japanese
        formatter.dateFormat = "E"
        return formatter
    }()
}

// Helper functions
func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)時間\(minutes)分"
    } else {
        return "\(minutes)分"
    }
}