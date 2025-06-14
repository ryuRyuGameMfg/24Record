import SwiftUI
import UIKit
import SwiftData

// 時間を起床・就寝時間の範囲内に制限するグローバル関数
@MainActor
private func constrainToWakeSleepTime(_ time: Date, for date: Date) -> Date {
    let routineSettings = DailyRoutineSettings.shared
    let wakeTime = routineSettings.getWakeUpTime(for: date)
    let bedTime = routineSettings.getBedTime(for: date)
    
    // 起床時間より前の場合は起床時間に設定
    if time < wakeTime {
        return wakeTime
    }
    
    // 就寝時間より後の場合は就寝時間に設定
    if time > bedTime {
        return bedTime
    }
    
    return time
}

public struct MainView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var showingUnifiedTaskAdd = false
    @State private var suggestedStartTime: Date?
    @State private var suggestedEndTime: Date?
    @State private var showingStatistics = false
    @State private var showingRoutineSettings = false
    @State private var showingAnalytics = false
    @State private var showingPremiumSubscription = false
    @State private var selectedTab = 0
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var routineSettings = DailyRoutineSettings.shared
    
    // Reordering removed for better UX
    
    // Loading states for visual feedback
    @State private var isLoadingTasks = false
    @State private var operationInProgress = false
    
    // Timeline layout constants
    private let hourHeight: CGFloat = 80
    private let timeLineWidth: CGFloat = 50
    
    // Month calendar dates
    private var calendarDates: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: viewModel.selectedDate)?.start ?? viewModel.selectedDate
        let range = calendar.range(of: .day, in: .month, for: viewModel.selectedDate) ?? 0..<31
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Timeline Tab
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                ZStack {
                    VStack(spacing: 0) {
                        // Header with month/year
                        headerView
                        
                        // Horizontal calendar
                        monthCalendarView
                            .padding(.horizontal)
                        
                        // Timeline content with improved scroll behavior
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                timelineContent(proxy: proxy)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 100) // Extra bottom padding for FAB
                            }
                            .scrollBounceBehavior(.basedOnSize) // Better bounce behavior
                            .scrollContentBackground(.hidden) // Hide default background
                        }
                    }
                    
                    // Loading overlay with higher z-index
                    if isLoadingTasks || operationInProgress {
                        loadingOverlay
                            .zIndex(1000) // Ensure it's above everything including FAB
                    }
                }
                
                // Floating action button - improved size and positioning
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            suggestedStartTime = nil
                            suggestedEndTime = nil
                            showingUnifiedTaskAdd = true
                        }) {
                            ZStack {
                                // Background with better shadow
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56) // Slightly smaller but still accessible
                                    .shadow(color: Color.pink.opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                // Icon with better visual hierarchy
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingUnifiedTaskAdd)
                        .padding(.trailing, 20)
                        .padding(.bottom, 24) // Better bottom spacing
                    }
                }
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("タイムライン")
            }
            .tag(0)
            
            // Analytics Tab
            AnalyticsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("分析")
                }
                .tag(1)
            
            // AI suggestions tab removed
            
            // Settings Tab
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(.pink)
        .background(Color.black)
        .onAppear {
            // Set TabBar appearance for consistent dark theme
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
            tabBarAppearance.shadowColor = .clear
            tabBarAppearance.shadowImage = UIImage()
            
            // Configure tab bar item appearance
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPink
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemPink]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        .sheet(isPresented: $showingUnifiedTaskAdd) {
            UnifiedTaskAddView(
                viewModel: viewModel,
                isPresented: $showingUnifiedTaskAdd,
                suggestedStartTime: suggestedStartTime,
                suggestedEndTime: suggestedEndTime
            )
        }
        .onChange(of: showingUnifiedTaskAdd) { oldValue, newValue in
            if oldValue && !newValue {
                // Sheet was dismissed, trigger refresh
                viewModel.refreshTrigger = UUID()
            }
        }
        .sheet(isPresented: $showingRoutineSettings) {
            DailyRoutineSettingsView()
        }
        .sheet(isPresented: $showingPremiumSubscription) {
            PremiumSubscriptionView()
        }
        // Reorder functionality removed
    }
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 12) {
                    Text(monthYearText)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Today button
                    if !Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()) {
                        Button("今日") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedDate = Date()
                            }
                        }
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .strokeBorder(Color.pink.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                
                HStack(spacing: 8) {
                    Text("タイムライン")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    // Premium status indicator (smaller)
                    if !storeManager.isPremium {
                        Button(action: {
                            showingPremiumSubscription = true
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                Text("Pro")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Pro")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.pink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .strokeBorder(Color.pink.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: {
                selectedTab = 2
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(.title3))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var monthCalendarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    ForEach(calendarDates, id: \.self) { date in
                        MainCalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedDate = date
                                }
                            },
                            viewModel: viewModel
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    // 今日の日付にスクロール
                    let today = Calendar.current.startOfDay(for: Date())
                    proxy.scrollTo(today, anchor: .center)
                }
                .onChange(of: viewModel.selectedDate) {
                    withAnimation {
                        proxy.scrollTo(viewModel.selectedDate, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    private func timelineContent(proxy: ScrollViewProxy) -> some View {
        // Force refresh when trigger changes
        let _ = viewModel.refreshTrigger
        
        // Get all blocks including routine tasks
        let allBlocks = getAllBlocksWithRoutine().sorted { $0.startTime < $1.startTime }
        
        return ZStack(alignment: .leading) {
            // Background timeline axis
            timelineAxisBackground
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Current time indicator
            currentTimeIndicator
            
            HStack(spacing: 0) {
                // Left spacer for timeline
                Spacer()
                    .frame(width: 66)
                
                // Main content with optimized layout
                LazyVStack(spacing: 4, pinnedViews: []) {
            
            if allBlocks.isEmpty {
                // Empty state with rectangular add button
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("今日はまだタスクがありません")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("最初のタスクを追加してスケジュールを始めましょう")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Rectangular add task button
                    AddTaskButtonView(
                        title: "最初のタスクを追加",
                        subtitle: "1日のスケジュールを開始",
                        action: {
                            suggestedStartTime = nil
                            suggestedEndTime = nil
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showingUnifiedTaskAdd = true
                            }
                        }
                    )
                }
                .padding(.top, 80)
            } else {
                // Display all tasks with improved animations
                ForEach(Array(allBlocks.enumerated()), id: \.element.id) { index, block in
                    VStack(spacing: 8) {
                        LongPressDeleteTaskView(
                            block: block,
                            viewModel: viewModel
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8)
                                .combined(with: .opacity)
                                .combined(with: .move(edge: .trailing)),
                            removal: .scale(scale: 0.8)
                                .combined(with: .opacity)
                                .combined(with: .move(edge: .leading))
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: allBlocks.map { $0.id })
                        .id("task_\(block.id.uuidString)")
                        
                        // Add gap indicator between tasks if needed
                        if index < allBlocks.count - 1 {
                            let nextBlock = allBlocks[index + 1]
                            let gapDuration = nextBlock.startTime.timeIntervalSince(block.endTime)
                            
                            if gapDuration >= 3600 { // Show gap if 1 hour or more
                                ChainGapDisplayView(
                                    fromTime: block.endTime,
                                    toTime: nextBlock.startTime,
                                    onAddTask: { startTime in
                                        suggestedStartTime = block.endTime
                                        suggestedEndTime = block.endTime.addingTimeInterval(3600)
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            showingUnifiedTaskAdd = true
                                        }
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: gapDuration)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // Add next task button only if not ending with bedtime
                if !allBlocks.isEmpty {
                    let lastBlock = allBlocks.last!
                    let isBedtimeTask = lastBlock.title.contains("就寝") || lastBlock.title.contains("寝る") || lastBlock.title.contains("睡眠")
                    
                    // Next task add button - only show if not bedtime
                    if !isBedtimeTask {
                        TimelineAddButtonView(
                            previousEndTime: lastBlock.endTime,
                            isLastButton: true,
                            action: { startTime in
                                suggestedStartTime = startTime
                                suggestedEndTime = startTime.addingTimeInterval(3600) // Default 1 hour
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showingUnifiedTaskAdd = true
                                }
                            }
                        )
                    }
                    
                    // Free time display - positioned after tasks but before bedtime
                    let freeTimeInfo = calculateFreeTime(allBlocks: allBlocks)
                    if freeTimeInfo.totalFreeTime > 0 {
                        FreeTimeDisplayView(
                            freeTimeMinutes: freeTimeInfo.totalFreeTime,
                            nextAvailableTime: freeTimeInfo.nextAvailableTime
                        )
                        .padding(.top, 16)
                    }
                }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Current Time Indicator
    private var currentTimeIndicator: some View {
        Group {
            if Calendar.current.isDate(Date(), inSameDayAs: viewModel.selectedDate) {
                CurrentTimeLineView(selectedDate: viewModel.selectedDate)
                    .padding(.leading, 66) // Offset for timeline labels
            }
        }
    }
    
    // MARK: - Timeline Axis Background
    private var timelineAxisBackground: some View {
        VStack(spacing: 0) {
            ForEach(getTimelineHours(), id: \.self) { hour in
                TimelineHourMarker(
                    hour: hour,
                    isCurrentHour: isCurrentHour(hour),
                    height: hourHeight
                )
            }
        }
    }
    
    private func getTimelineHours() -> [Int] {
        let routineSettings = DailyRoutineSettings.shared
        let wakeTime = routineSettings.getWakeUpTime(for: viewModel.selectedDate)
        let bedTime = routineSettings.getBedTime(for: viewModel.selectedDate)
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: wakeTime)
        let endHour = calendar.component(.hour, from: bedTime)
        
        // Create array of hours from wake to bed time
        var hours: [Int] = []
        var currentHour = startHour
        
        while currentHour != endHour {
            hours.append(currentHour)
            currentHour = (currentHour + 1) % 24
        }
        hours.append(endHour) // Include end hour
        
        return hours
    }
    
    private func isCurrentHour(_ hour: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        // Only show as current if it's today
        return calendar.isDate(now, inSameDayAs: viewModel.selectedDate) && currentHour == hour
    }
    
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private func getBlocksForHour(_ hour: Int) -> [SDTimeBlock] {
        let blocks = viewModel.getTimeBlocks(for: viewModel.selectedDate)
        let calendar = Calendar.current
        
        return blocks.filter { block in
            let blockHour = calendar.component(.hour, from: block.startTime)
            return blockHour == hour || 
                   (calendar.component(.hour, from: block.endTime) == hour && 
                    calendar.component(.minute, from: block.endTime) > 0) ||
                   (blockHour < hour && calendar.component(.hour, from: block.endTime) > hour)
        }
    }
    
    private func createTimeForHour(_ hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents) ?? viewModel.selectedDate
    }
    
    // MARK: - Helper Functions
    
    
    private func isSameTimeRange(_ block1: SDTimeBlock, _ block2: SDTimeBlock) -> Bool {
        let calendar = Calendar.current
        let hour1 = calendar.component(.hour, from: block1.startTime)
        let hour2 = calendar.component(.hour, from: block2.startTime)
        return abs(hour1 - hour2) <= 1 // Same or adjacent hour
    }
    
    
    // MARK: - Get All Blocks Including Routine
    private func getAllBlocksWithRoutine() -> [SDTimeBlock] {
        var allBlocks = viewModel.getTimeBlocks(for: viewModel.selectedDate)
        
        // Add routine tasks if enabled
        if routineSettings.isRoutineEnabled {
            let routineTasks = routineSettings.generateRoutineTasks(for: viewModel.selectedDate)
            
            for routine in routineTasks {
                // Check if routine task already exists
                let routineExists = allBlocks.contains { block in
                    let calendar = Calendar.current
                    return block.title == routine.title &&
                           calendar.isDate(block.startTime, equalTo: routine.startTime, toGranularity: .minute)
                }
                
                if !routineExists {
                    // Create temporary routine block
                    if let category = viewModel.getCategories().first(where: { $0.name == routine.categoryName }) {
                        // Create a temporary block for display
                        let routineBlock = SDTimeBlock(
                            title: routine.title,
                            startTime: routine.startTime,
                            endTime: routine.endTime,
                            category: category,
                            notes: "毎日の固定ルーティン",
                            isCompleted: false
                        )
                        // Mark as routine for special styling
                        routineBlock.isRoutine = true
                        allBlocks.append(routineBlock)
                    }
                }
            }
        }
        
        return allBlocks
    }
    
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    .scaleEffect(1.2)
                
                Text(operationInProgress ? "処理中..." : "読み込み中...")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.pink.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isLoadingTasks)
        .animation(.easeInOut(duration: 0.2), value: operationInProgress)
    }
    
    
    // MARK: - Free Time Calculation
    
    private func calculateFreeTime(allBlocks: [SDTimeBlock]) -> (totalFreeTime: Int, nextAvailableTime: Date?) {
        let routineSettings = DailyRoutineSettings.shared
        
        let wakeTime = routineSettings.getWakeUpTime(for: viewModel.selectedDate)
        let bedTime = routineSettings.getBedTime(for: viewModel.selectedDate)
        
        // Calculate total available time (wake to bed)
        let totalAvailableMinutes = Int(bedTime.timeIntervalSince(wakeTime) / 60)
        
        // Calculate total used time
        let totalUsedMinutes = allBlocks.reduce(0) { total, block in
            total + Int(block.duration / 60)
        }
        
        // Calculate free time
        let freeTimeMinutes = totalAvailableMinutes - totalUsedMinutes
        
        // Find next available time slot
        let sortedBlocks = allBlocks.sorted { $0.startTime < $1.startTime }
        var nextAvailableTime: Date?
        
        if let lastBlock = sortedBlocks.last {
            nextAvailableTime = lastBlock.endTime
        } else {
            nextAvailableTime = wakeTime
        }
        
        return (max(0, freeTimeMinutes), nextAvailableTime)
    }
    
    // Reorder functions removed for better UX
}

struct MainCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(weekdayFormatter.string(from: date))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(dayFormatter.string(from: date))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? 
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : 
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                            )
                    )
                
                // Task indicator
                Circle()
                    .fill(.pink)
                    .frame(width: 4, height: 4)
                    .opacity(hasTasksOnDate ? 1.0 : 0.0)
            }
        }
        .frame(width: 50)
    }
    
    private var hasTasksOnDate: Bool {
        !viewModel.getTimeBlocks(for: date).isEmpty
    }
}

struct InteractiveHourRowView: View {
    let hour: Int
    let blocks: [SDTimeBlock]
    let selectedDate: Date
    let viewModel: SwiftDataTimeTrackingViewModel
    let hourHeight: CGFloat
    let timeLineWidth: CGFloat
    let onTapEmptySpace: (Int) -> Void
    let onDragChanged: (DragGesture.Value, Date) -> Void
    let onDragEnded: (DragGesture.Value, Date) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time label
            VStack(spacing: 4) {
                Text(String(format: "%02d:00", hour))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                // Dotted line connector
                VStack(spacing: 4) {
                    ForEach(0..<8, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2, height: 2)
                    }
                }
                .frame(height: hourHeight - 16)
            }
            .frame(width: timeLineWidth)
            
            // Content area with drag support
            ZStack {
                // Background drag area
                dragBackgroundArea
                
                // Existing task blocks
                VStack(alignment: .leading, spacing: 8) {
                    if blocks.isEmpty {
                        emptySpaceView
                    } else {
                        ForEach(blocks) { block in
                            LongPressDeleteTaskView(
                                block: block,
                                viewModel: viewModel
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            
            Spacer()
        }
        .frame(height: hourHeight)
    }
    
    private var dragBackgroundArea: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let startTime = createTimeForDrag(hour: hour, dragLocation: value.startLocation)
                        onDragChanged(value, startTime)
                    }
                    .onEnded { value in
                        let startTime = createTimeForDrag(hour: hour, dragLocation: value.startLocation)
                        onDragEnded(value, startTime)
                    }
            )
    }
    
    private var emptySpaceView: some View {
        Group {
            // 睡眠時間（夜22時〜朝6時）のみ左側にテキストを表示
            if isSleepingHour(hour) {
                Button(action: { onTapEmptySpace(0) }) {
                    HStack {
                        Text(sleepingTimeText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .frame(height: hourHeight - 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // それ以外の時間は空き時間の促しとタスク追加ボタンを表示
                Color.clear
                    .frame(height: hourHeight - 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTapEmptySpace(0)
                    }
            }
        }
    }
    
    private func isSleepingHour(_ hour: Int) -> Bool {
        // 夜22時〜朝6時を睡眠時間とする
        return hour >= 22 || hour < 6
    }
    
    private var sleepingTimeText: String {
        if hour >= 22 || hour <= 3 {
            return "おやすみなさい"
        } else {
            return "おはようございます"
        }
    }
    
    private func createTimeForDrag(hour: Int, dragLocation: CGPoint) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Calculate minute based on y position within the hour
        let minuteInHour = Int((dragLocation.y / hourHeight) * 60)
        let clampedMinute = max(0, min(59, minuteInHour))
        
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = clampedMinute
        
        return calendar.date(from: dateComponents) ?? selectedDate
    }
}

struct ModernTaskBlockView: View {
    let block: SDTimeBlock
    @State private var showingEdit = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @FocusState private var isTitleFieldFocused: Bool
    
    // 15分を基準とした時間比例の高さ計算
    private var taskHeight: CGFloat {
        let durationMinutes = block.duration / 60 // 分単位
        let baseHeight: CGFloat = 60 // 15分の基本高さ（短縮）
        let minimumHeight: CGFloat = 50 // 最小高さ（短縮）
        let maximumHeight: CGFloat = 100 // 最大高さを制限
        
        // 15分を基準として比例計算
        let proportionalHeight = (durationMinutes / 15.0) * baseHeight
        
        // 段階的な高さ調整（より控えめに）
        let adjustedHeight = switch durationMinutes {
        case 0..<10:
            max(minimumHeight, proportionalHeight * 0.9) // 10分未満は少し縮小
        case 10..<15:
            max(minimumHeight, proportionalHeight * 0.95) // 15分未満は若干縮小
        case 15..<30:
            proportionalHeight // 15-30分は比例通り
        case 30..<60:
            proportionalHeight * 1.05 // 30-60分は少し拡大（控えめ）
        case 60..<120:
            proportionalHeight * 1.1 // 1-2時間はさらに拡大（控えめ）
        default:
            proportionalHeight * 1.15 // 2時間以上は最大拡大（控えめ）
        }
        
        return min(maximumHeight, adjustedHeight) // 最大高さを制限
    }
    
    var body: some View {
        Button(action: { 
            if !isEditing {
                showingEdit = true
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Left side: Icon - 固定サイズで上部配置
                VStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [block.color, block.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44) // サイズを少し小さく
                        
                        if block.isRoutine {
                            // Special icon for routine tasks
                            Image(systemName: "clock.badge.checkmark.fill")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: block.category?.icon ?? "circle")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: block.color.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Spacer(minLength: 0) // 残りスペースを埋める
                }
                
                // Middle: Task info - スクリーンショットのレイアウトに合わせて
                VStack(alignment: .leading, spacing: 6) {
                    // タイトルを上部に配置
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Duration and time first - スクリーンショットのように
                            Text(timeText)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            // Title
                            if isEditing {
                                TextField("タイトル", text: $editingTitle)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .focused($isTitleFieldFocused)
                                    .onSubmit {
                                        saveTitle()
                                    }
                            } else {
                                Text(block.title)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .onTapGesture {
                                        startEditingTitle()
                                    }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Duration at bottom if there are notes
                    if !block.notes.isEmpty {
                        Text(block.notes)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                // Right: Status circle - スクリーンショットのように
                VStack {
                    Circle()
                        .strokeBorder(statusColor, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(block.isCompleted ? statusColor : Color.clear)
                        )
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, taskHeight > 70 ? 14 : 10) // 高さに応じてパディング調整
            .frame(minHeight: taskHeight) // 時間に応じた高さを適用
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: block.isRoutine ? [
                                Color(white: 0.15).opacity(0.8),
                                Color(white: 0.10).opacity(0.8)
                            ] : [
                                Color(white: 0.12),
                                Color(white: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                block.isRoutine ? 
                                    block.color.opacity(0.5) : 
                                    block.color.opacity(0.3),
                                lineWidth: block.isRoutine ? 2 : 1
                            )
                    )
                    .overlay(
                        // Badge for routine tasks
                        block.isRoutine ? 
                        HStack {
                            Spacer()
                            VStack {
                                Text("毎日")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(block.color.opacity(0.8))
                                    )
                                    .padding(8)
                                Spacer()
                            }
                        } : nil
                    )
            )
            .shadow(color: block.color.opacity(0.2), radius: 6, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    if isEditing {
                        // Don't trigger button action while editing
                    }
                }
        )
    }
    
    private func startEditingTitle() {
        editingTitle = block.title
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTitleFieldFocused = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveTitle() {
        if !editingTitle.isEmpty && editingTitle != block.title {
            block.title = editingTitle
            // Save through view model if needed
            // viewModel.updateTimeBlock(block, title: editingTitle)
            
            // Success feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        isEditing = false
        isTitleFieldFocused = false
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: block.startTime)
        let endTime = formatter.string(from: block.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
    
    private var durationText: String {
        let duration = Int(block.duration / 60)
        if duration >= 60 {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes > 0 {
                return "\(hours)時間\(minutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(duration)分"
        }
    }
    
    // 時間長さによる視覚的な強調表示
    private var durationIndicatorColor: Color {
        let durationMinutes = block.duration / 60
        switch durationMinutes {
        case 0..<15:
            return .yellow.opacity(0.8) // 短時間タスク
        case 15..<30:
            return .green.opacity(0.8) // 標準タスク
        case 30..<60:
            return .blue.opacity(0.8) // 中時間タスク
        case 60..<120:
            return .purple.opacity(0.8) // 長時間タスク
        default:
            return .red.opacity(0.8) // 超長時間タスク
        }
    }
    
    private var statusColor: Color {
        if block.isCompleted {
            return .teal
        } else {
            return .pink
        }
    }
}

// MARK: - Supporting Views for Task-based Timeline

struct TimelineRowView: View {
    let block: SDTimeBlock?
    let viewModel: SwiftDataTimeTrackingViewModel
    let selectedDate: Date
    let isFirst: Bool
    let isLast: Bool
    let nextBlock: SDTimeBlock?
    let lastEndTime: Date?
    let onAddTask: ((Date) -> Void)?
    
    init(block: SDTimeBlock?, viewModel: SwiftDataTimeTrackingViewModel, selectedDate: Date, isFirst: Bool, isLast: Bool, nextBlock: SDTimeBlock?, lastEndTime: Date? = nil, onAddTask: ((Date) -> Void)? = nil) {
        self.block = block
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self.isFirst = isFirst
        self.isLast = isLast
        self.nextBlock = nextBlock
        self.lastEndTime = lastEndTime
        self.onAddTask = onAddTask
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let block = block {
                // Task without chain design
                LongPressDeleteTaskView(
                    block: block,
                    viewModel: viewModel
                )
                .padding(.vertical, 8)
                
            } else if let lastEndTime = lastEndTime {
                // Final gap indicator (display only)
                ChainGapDisplayView(
                    fromTime: lastEndTime,
                    toTime: nil
                )
            }
        }
    }
    
    private var timeText: String {
        guard let block = block else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: block.startTime)
    }
    
    private var endTimeText: String {
        guard let lastEndTime = lastEndTime else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: lastEndTime)
    }
    
    private var hasGapBefore: Bool {
        // Logic to determine if there's a significant gap before this task
        // This would be determined by the parent view based on time differences
        return false // Simplified for now
    }
    
    private var hasGapAfter: Bool {
        guard let block = block, let nextBlock = nextBlock else { return isLast }
        let gapDuration = nextBlock.startTime.timeIntervalSince(block.endTime)
        return gapDuration > 300 // More than 5 minutes gap
    }
}

struct TimeMarkerView: View {
    let time: Date
    let label: String
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(timeText)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
            
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.6), .pink.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct ChainGapDisplayView: View {
    let fromTime: Date
    let toTime: Date?
    let onAddTask: ((Date) -> Void)?
    
    init(fromTime: Date, toTime: Date?, onAddTask: ((Date) -> Void)? = nil) {
        self.fromTime = fromTime
        self.toTime = toTime
        self.onAddTask = onAddTask
    }
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "空き時間"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の休憩"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の休憩"
            } else {
                return "\(hours)時間\(remainingMinutes)分の休憩"
            }
        }
    }
    
    var body: some View {
        let duration = toTime?.timeIntervalSince(fromTime) ?? 0
        let isLongGap = duration >= 3600 // 1 hour or more
        
        VStack(spacing: 0) {
            // Centered chain connection with dotted line
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .frame(height: 20)
            
            // Gap display with integrated add button
            Button(action: {
                if let onAddTask = onAddTask {
                    onAddTask(fromTime)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(gapText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isLongGap, let _ = onAddTask {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(.caption2, design: .rounded))
                            Text("追加")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.pink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isLongGap && onAddTask != nil ? Color.pink.opacity(0.3) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .disabled(onAddTask == nil || !isLongGap)
        }
    }
}

struct TimelineGapRowView: View {
    let fromTime: Date
    let toTime: Date?
    let onTap: () -> Void
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "時間の余裕があります？体調の計画を立てましょう。"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の余裕があります"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の余裕があります"
            } else {
                return "\(hours)時間\(remainingMinutes)分の余裕があります"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text(gapText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.pink.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineHeaderView: View {
    let time: Date
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
    
    private var dateText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        switch hour {
        case 0..<6:
            return "深夜"
        case 6..<12:
            return "午前"
        case 12..<18:
            return "午後"
        case 18..<22:
            return "夕方"
        default:
            return "夜"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(timeText)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

struct TimelineGapView: View {
    let fromTime: Date
    let toTime: Date?
    let onTap: () -> Void
    
    private var gapText: String {
        guard let toTime = toTime else {
            return "次のタスクを追加"
        }
        
        let duration = toTime.timeIntervalSince(fromTime)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes)分の空き時間"
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if remainingMinutes == 0 {
                return "\(hours)時間の空き時間"
            } else {
                return "\(hours)時間\(remainingMinutes)分の空き時間"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Dotted line
                HStack {
                    ForEach(0..<20, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                }
                
                // Gap info
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pink)
                    
                    Text(gapText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// MARK: - Task Add Button Components

struct AddTaskButtonView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.title2, design: .rounded))
                        .foregroundColor(.pink)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineAddButtonView: View {
    let previousEndTime: Date?
    let isLastButton: Bool
    let action: (Date) -> Void
    
    private var nextStartTime: Date {
        guard let endTime = previousEndTime else {
            // If no previous task, start from next hour
            let calendar = Calendar.current
            let now = Date()
            let nextHour = calendar.dateInterval(of: .hour, for: now)?.end ?? now
            return nextHour
        }
        
        // Start 15 minutes after the previous task ends
        return endTime.addingTimeInterval(900)
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: nextStartTime)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top chain connector
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .frame(height: 20)
            
            Button(action: {
                action(nextStartTime)
            }) {
                // Add button content
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.pink.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("次のタスクを追加")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("\(timeText)から開始")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.pink.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Free Time Display View
struct FreeTimeDisplayView: View {
    let freeTimeMinutes: Int
    let nextAvailableTime: Date?
    
    private var freeTimeText: String {
        let hours = freeTimeMinutes / 60
        let minutes = freeTimeMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "自由時間 \(hours)時間\(minutes)分"
        } else if hours > 0 {
            return "自由時間 \(hours)時間"
        } else if minutes > 0 {
            return "自由時間 \(minutes)分"
        } else {
            return "自由時間なし"
        }
    }
    
    private var suggestionText: String {
        if freeTimeMinutes > 120 {
            return "余裕があります。新しいタスクを追加しませんか？"
        } else if freeTimeMinutes > 60 {
            return "適度なスケジュールです"
        } else if freeTimeMinutes > 0 {
            return "忙しい一日ですね"
        } else {
            return "スケジュールが詰まっています"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.green)
                
                Text(freeTimeText)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Text(suggestionText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Current Time Line View
struct CurrentTimeLineView: View {
    let selectedDate: Date
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var timeOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // Calculate position based on hour and minute
        let hourHeight: CGFloat = 80 // Match MainView hourHeight
        
        // Calculate offset from start of day
        let routineSettings = DailyRoutineSettings.shared
        let wakeTime = routineSettings.getWakeUpTime(for: selectedDate)
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        
        // Calculate minutes since wake time
        let currentTotalMinutes = hour * 60 + minute
        let wakeTotalMinutes = wakeHour * 60 + wakeMinute
        let offsetMinutes = currentTotalMinutes - wakeTotalMinutes
        
        // Convert to position
        return max(0, CGFloat(offsetMinutes) / 60.0 * hourHeight)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: timeOffset)
            
            ZStack {
                // Blue line extending across the full width
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 2)
                
                HStack {
                    // Current time indicator circle on left
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        )
                    
                    Spacer()
                    
                    // Time text on right
                    Text(timeText)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
            
            Spacer()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            currentTime = Date()
        }
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentTime)
    }
}

// MARK: - Timeline Hour Marker
struct TimelineHourMarker: View {
    let hour: Int
    let isCurrentHour: Bool
    let height: CGFloat
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: 0)
        let time = calendar.date(from: components) ?? Date()
        
        return formatter.string(from: time)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                // Time label on left
                VStack {
                    Text(timeText)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(isCurrentHour ? .bold : .medium)
                        .foregroundColor(isCurrentHour ? .blue : .gray)
                        .frame(width: 50, alignment: .trailing)
                    
                    Spacer()
                }
                .frame(height: height)
                
                // Vertical line section
                VStack(spacing: 0) {
                    // Solid line at hour mark
                    Rectangle()
                        .fill(isCurrentHour ? Color.blue.opacity(0.8) : Color.gray.opacity(0.4))
                        .frame(width: 2, height: 8)
                    
                    // Dotted line continuation
                    VStack(spacing: 2) {
                        ForEach(0..<Int((height-8)/4), id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 1, height: 1)
                        }
                    }
                }
                .frame(height: height)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SDTimeBlock.self, SDCategory.self, SDTag.self, SDTaskTemplate.self])
}