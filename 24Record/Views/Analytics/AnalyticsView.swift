import SwiftUI
import Charts
import SwiftData

// MARK: - Analytics Period Enum
enum AnalyticsPeriod: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var localizedName: String {
        switch self {
        case .daily: return L10n.daily
        case .weekly: return L10n.weekly
        case .monthly: return L10n.monthly
        case .yearly: return L10n.yearly
        }
    }
}

// MARK: - Analytics Data Models
struct AnalyticsData {
    let period: AnalyticsPeriod
    let categoryStats: [CategoryAnalytics]
    let totalTime: TimeInterval
    let taskCount: Int
    let mostProductiveHour: Int?
    let averageSessionDuration: TimeInterval
    let completionRate: Double
    let trends: [TrendPoint]
}

struct CategoryAnalytics: Identifiable {
    let id = UUID()
    let category: SDCategory
    var totalTime: TimeInterval
    var taskCount: Int
    let percentage: Double
    let averageDuration: TimeInterval
    let mostActiveHour: Int?
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: TimeInterval
    let label: String
}

struct HourlyActivity: Identifiable {
    let id = UUID()
    let hour: Int
    let totalTime: TimeInterval
    let taskCount: Int
}

// MARK: - Main Analytics View
struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: SwiftDataTimeTrackingViewModel
    @State private var selectedPeriod: AnalyticsPeriod = .weekly
    @State private var selectedDate = Date()
    @State private var analyticsData: AnalyticsData?
    @State private var isLoading = false
    @State private var hourlyData: [HourlyActivity] = []
    
    init(viewModel: SwiftDataTimeTrackingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                    // Period Selector
                    periodSelector
                    
                    // Date Selector
                    dateSelector
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(40)
                    } else if let data = analyticsData {
                        // Summary Cards
                        summaryCards(data: data)
                        
                        // Time Distribution Pie Chart
                        if !data.categoryStats.isEmpty {
                            timeDistributionChart(data: data)
                        }
                        
                        // Category Bar Chart
                        if !data.categoryStats.isEmpty {
                            categoryBarChart(data: data)
                        }
                        
                        // Trend Line Chart
                        if !data.trends.isEmpty {
                            trendChart(data: data)
                        }
                        
                        // Hourly Activity Chart
                        if !hourlyData.isEmpty {
                            hourlyActivityChart()
                        }
                        
                        // Detailed Statistics
                        detailedStatistics(data: data)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            } // Close ZStack
            .navigationTitle(L10n.analytics)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAnalyticsData()
                // Set navigation bar appearance
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            .onChange(of: selectedPeriod) { _, _ in
                loadAnalyticsData()
            }
            .onChange(of: selectedDate) { _, _ in
                loadAnalyticsData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker(L10n.duration, selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onAppear {
            // Set segmented control appearance for dark theme
            UISegmentedControl.appearance().backgroundColor = UIColor(white: 0.1, alpha: 1.0)
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemPink
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor.white
            ], for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor.white
            ], for: .selected)
        }
    }
    
    // MARK: - Date Selector
    private var dateSelector: some View {
        HStack {
            Button(action: previousPeriod) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(dateRangeText)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextPeriod) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Summary Cards
    private func summaryCards(data: AnalyticsData) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            summaryCard(
                title: L10n.totalTime,
                value: formatDuration(data.totalTime),
                icon: "clock.fill",
                color: .blue
            )
            
            summaryCard(
                title: L10n.taskCount,
                value: "\(data.taskCount)個",
                icon: "list.bullet",
                color: .green
            )
            
            summaryCard(
                title: L10n.averageSession,
                value: formatDuration(data.averageSessionDuration),
                icon: "stopwatch.fill",
                color: .orange
            )
            
            summaryCard(
                title: L10n.completionRate,
                value: String(format: "%.1f%%", data.completionRate * 100),
                icon: "checkmark.circle.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Time Distribution Pie Chart
    private func timeDistributionChart(data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.timeDistribution)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Chart {
                ForEach(data.categoryStats.prefix(8)) { stat in
                    SectorMark(
                        angle: .value("時間", stat.totalTime),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.0
                    )
                    .foregroundStyle(stat.category.color.gradient)
                    .opacity(0.8)
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .center, spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(data.categoryStats.prefix(8)) { stat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(stat.category.color)
                                .frame(width: 8, height: 8)
                            
                            Text(stat.category.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Category Bar Chart
    private func categoryBarChart(data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.categoryByTime)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Chart {
                ForEach(data.categoryStats.prefix(10)) { stat in
                    BarMark(
                        x: .value("時間", stat.totalTime / 3600),
                        y: .value("カテゴリー", stat.category.name)
                    )
                    .foregroundStyle(stat.category.color.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: max(200, CGFloat(min(data.categoryStats.count, 10)) * 30))
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let categoryName = value.as(String.self) {
                            Text(categoryName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Trend Chart
    private func trendChart(data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.timeTrend)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Chart {
                ForEach(data.trends) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("時間", point.value / 3600)
                    )
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(30)
                    .foregroundStyle(.blue.gradient)
                    
                    AreaMark(
                        x: .value("日付", point.date),
                        y: .value("時間", point.value / 3600)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.gradient.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDateForTrend(date))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Hourly Activity Chart
    private func hourlyActivityChart() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.hourlyActivity)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Chart {
                ForEach(hourlyData) { data in
                    BarMark(
                        x: .value("時間", data.hour),
                        y: .value("時間", data.totalTime / 3600)
                    )
                    .foregroundStyle(.mint.gradient)
                    .cornerRadius(2)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: Array(0...23)) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Detailed Statistics
    private func detailedStatistics(data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.detailedStatistics)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(data.categoryStats.prefix(5)) { stat in
                    HStack {
                        // Category info
                        HStack(spacing: 12) {
                            Circle()
                                .fill(stat.category.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(stat.taskCount)" + L10n.tasks)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Statistics
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDuration(stat.totalTime))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(String(format: "%.1f%%", stat.percentage))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if stat.id != data.categoryStats.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(L10n.noDataAvailable)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(L10n.noTasksInPeriod)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    private var dateRangeText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        switch selectedPeriod {
        case .daily:
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: selectedDate)
        case .weekly:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        case .monthly:
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: selectedDate)
        case .yearly:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: selectedDate)
        }
    }
    
    // MARK: - Helper Methods
    private func previousPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .weekly:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .monthly:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        case .yearly:
            selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .weekly:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .monthly:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        case .yearly:
            selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func formatDateForTrend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        switch selectedPeriod {
        case .daily, .weekly:
            formatter.dateFormat = "M/d"
        case .monthly:
            formatter.dateFormat = "M/d"
        case .yearly:
            formatter.dateFormat = "M月"
        }
        
        return formatter.string(from: date)
    }
    
    // MARK: - Data Loading
    private func loadAnalyticsData() {
        isLoading = true
        
        Task {
            await MainActor.run {
                let blocks = getTimeBlocksForSelectedPeriod()
                analyticsData = calculateAnalytics(from: blocks)
                hourlyData = calculateHourlyActivity(from: blocks)
                isLoading = false
            }
        }
    }
    
    private func getTimeBlocksForSelectedPeriod() -> [SDTimeBlock] {
        let calendar = Calendar.current
        var startDate: Date
        var endDate: Date
        
        switch selectedPeriod {
        case .daily:
            startDate = calendar.startOfDay(for: selectedDate)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        case .weekly:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate)
            startDate = weekInterval?.start ?? selectedDate
            endDate = weekInterval?.end ?? selectedDate
        case .monthly:
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)
            startDate = monthInterval?.start ?? selectedDate
            endDate = monthInterval?.end ?? selectedDate
        case .yearly:
            let yearInterval = calendar.dateInterval(of: .year, for: selectedDate)
            startDate = yearInterval?.start ?? selectedDate
            endDate = yearInterval?.end ?? selectedDate
        }
        
        let predicate = #Predicate<SDTimeBlock> { block in
            block.startTime >= startDate && block.startTime < endDate
        }
        
        let descriptor = FetchDescriptor<SDTimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch blocks for analytics: \(error)")
            return []
        }
    }
    
    private func calculateAnalytics(from blocks: [SDTimeBlock]) -> AnalyticsData {
        var categoryMap: [UUID: CategoryAnalytics] = [:]
        var totalTime: TimeInterval = 0
        var completedTasks = 0
        var hourlyActivity: [Int: TimeInterval] = [:]
        
        // Process each block
        for block in blocks {
            guard let category = block.category else { continue }
            
            let duration = block.duration
            totalTime += duration
            
            if block.isCompleted {
                completedTasks += 1
            }
            
            // Track hourly activity
            let hour = Calendar.current.component(.hour, from: block.startTime)
            hourlyActivity[hour, default: 0] += duration
            
            // Update category statistics
            if var existing = categoryMap[category.id] {
                existing.totalTime += duration
                existing.taskCount += 1
                categoryMap[category.id] = existing
            } else {
                categoryMap[category.id] = CategoryAnalytics(
                    category: category,
                    totalTime: duration,
                    taskCount: 1,
                    percentage: 0, // Will be calculated later
                    averageDuration: duration,
                    mostActiveHour: hour
                )
            }
        }
        
        // Calculate percentages and finalize category analytics
        let categoryStats = categoryMap.values.map { analytics in
            CategoryAnalytics(
                category: analytics.category,
                totalTime: analytics.totalTime,
                taskCount: analytics.taskCount,
                percentage: totalTime > 0 ? (analytics.totalTime / totalTime) * 100 : 0,
                averageDuration: analytics.totalTime / Double(analytics.taskCount),
                mostActiveHour: analytics.mostActiveHour
            )
        }.sorted { $0.totalTime > $1.totalTime }
        
        // Find most productive hour
        let mostProductiveHour = hourlyActivity.max(by: { $0.value < $1.value })?.key
        
        // Calculate completion rate
        let completionRate = blocks.isEmpty ? 0 : Double(completedTasks) / Double(blocks.count)
        
        // Calculate average session duration
        let averageSessionDuration = blocks.isEmpty ? 0 : totalTime / Double(blocks.count)
        
        // Generate trend data
        let trends = generateTrendData(from: blocks)
        
        return AnalyticsData(
            period: selectedPeriod,
            categoryStats: categoryStats,
            totalTime: totalTime,
            taskCount: blocks.count,
            mostProductiveHour: mostProductiveHour,
            averageSessionDuration: averageSessionDuration,
            completionRate: completionRate,
            trends: trends
        )
    }
    
    private func calculateHourlyActivity(from blocks: [SDTimeBlock]) -> [HourlyActivity] {
        var hourlyMap: [Int: (time: TimeInterval, count: Int)] = [:]
        
        for block in blocks {
            let hour = Calendar.current.component(.hour, from: block.startTime)
            let current = hourlyMap[hour] ?? (time: 0, count: 0)
            hourlyMap[hour] = (time: current.time + block.duration, count: current.count + 1)
        }
        
        return (0...23).map { hour in
            let data = hourlyMap[hour] ?? (time: 0, count: 0)
            return HourlyActivity(
                hour: hour,
                totalTime: data.time,
                taskCount: data.count
            )
        }
    }
    
    private func generateTrendData(from blocks: [SDTimeBlock]) -> [TrendPoint] {
        let calendar = Calendar.current
        var dailyTotals: [Date: TimeInterval] = [:]
        
        // Group by date and sum durations
        for block in blocks {
            let day = calendar.startOfDay(for: block.startTime)
            dailyTotals[day, default: 0] += block.duration
        }
        
        // Convert to trend points
        return dailyTotals.map { date, duration in
            TrendPoint(
                date: date,
                value: duration,
                label: formatDateForTrend(date)
            )
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Preview
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SDTimeBlock.self, configurations: config)
        let viewModel = SwiftDataTimeTrackingViewModel(modelContext: container.mainContext)
        
        AnalyticsView(viewModel: viewModel)
    }
}