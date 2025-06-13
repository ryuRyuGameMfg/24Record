import SwiftUI
import SwiftData

struct UnifiedTaskAddView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @Binding var isPresented: Bool
    let suggestedStartTime: Date?
    let suggestedEndTime: Date?
    let existingBlock: SDTimeBlock? // 編集時の既存データ
    let onSave: ((SDTimeBlock) -> Void)? // 編集時の保存コールバック
    let onDelete: (() -> Void)? // 編集時の削除コールバック
    
    @State private var selectedCategory: SDCategory?
    @State private var taskStartTime: Date
    @State private var taskEndTime: Date
    @State private var selectedDuration: TimeInterval = 3600
    @State private var taskMemo: String = ""
    @State private var showTimeSettings: Bool = false
    @State private var showingDeleteAlert = false
    @State private var showingPremiumGate = false
    @State private var premiumGateMessage = ""
    
    // 編集モードかどうかを判定
    private var isEditMode: Bool {
        existingBlock != nil
    }
    
    init(viewModel: SwiftDataTimeTrackingViewModel, isPresented: Binding<Bool>, suggestedStartTime: Date? = nil, suggestedEndTime: Date? = nil, existingBlock: SDTimeBlock? = nil, onSave: ((SDTimeBlock) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.suggestedStartTime = suggestedStartTime
        self.suggestedEndTime = suggestedEndTime
        self.existingBlock = existingBlock
        self.onSave = onSave
        self.onDelete = onDelete
        
        // 編集モードの場合は既存データで初期化、そうでなければ新規作成用の初期化
        if let existingBlock = existingBlock {
            self._taskStartTime = State(initialValue: existingBlock.startTime)
            self._taskEndTime = State(initialValue: existingBlock.endTime)
            self._selectedDuration = State(initialValue: existingBlock.endTime.timeIntervalSince(existingBlock.startTime))
            self._taskMemo = State(initialValue: existingBlock.notes)
            self._selectedCategory = State(initialValue: existingBlock.category)
        } else {
            let now = Date()
            self._taskStartTime = State(initialValue: suggestedStartTime ?? now)
            self._taskEndTime = State(initialValue: suggestedEndTime ?? (suggestedStartTime ?? now).addingTimeInterval(3600))
        }
    }
    
    // 起床・就寝時間の範囲を取得
    private var allowedTimeRange: ClosedRange<Date> {
        let routineSettings = DailyRoutineSettings.shared
        let wakeTime = routineSettings.getWakeUpTime(for: viewModel.selectedDate)
        let bedTime = routineSettings.getBedTime(for: viewModel.selectedDate)
        return wakeTime...bedTime
    }
    
    var body: some View {
        NavigationView {
            mainContentView
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if !isEditMode {
                let proposedEndTime = taskStartTime.addingTimeInterval(selectedDuration)
                taskEndTime = min(proposedEndTime, allowedTimeRange.upperBound)
                
                // デフォルトで右上のタスク（3番目のカテゴリ）を選択
                let categories = getMainCategories()
                if selectedCategory == nil && categories.count >= 3 {
                    selectedCategory = categories[2] // 0-based index, so 2 = 3rd item (top-right)
                }
            }
        }
        .alert("タスクを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                onDelete?()
                isPresented = false
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このタスクを削除してもよろしいですか？この操作は取り消せません。")
        }
        .premiumGate(
            isPresented: $showingPremiumGate,
            feature: "無制限のタスク作成",
            message: premiumGateMessage
        )
    }
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    scrollableContent
                    fixedBottomButton
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationTitle(isEditMode ? "タスクを編集" : "タスクを追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    isPresented = false
                }
                .foregroundColor(.pink)
            }
        }
    }
    
    private var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                categorySelector
                durationSelector
                timeSettingsSection
                memoField
                deleteButtonIfNeeded
            }
            .padding(.top, 10)
            .padding(.bottom, 50)
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリを選択")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            let columns = [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(getMainCategories().prefix(9))) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: {
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var durationSelector: some View {
        DurationQuickSelector(
            selectedDuration: $selectedDuration,
            onDurationChanged: { duration in
                let proposedEndTime = taskStartTime.addingTimeInterval(duration)
                taskEndTime = min(proposedEndTime, allowedTimeRange.upperBound)
            }
        )
        .padding(.horizontal, 16)
    }
    
    private var timeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            timeSettingsToggle
            
            if showTimeSettings {
                timePickersView
            } else {
                timeSummaryView
            }
        }
    }
    
    private var timeSettingsToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showTimeSettings.toggle()
            }
        }) {
            HStack {
                Text("開始・終了時刻（任意）")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: showTimeSettings ? "chevron.up" : "chevron.down")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var timePickersView: some View {
        VStack(spacing: 10) {
            startTimePicker
            endTimePicker
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var startTimePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("開始日時")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            DatePicker("", selection: $taskStartTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                )
                .padding(.horizontal, 16)
                .onChange(of: taskStartTime) { oldValue, newValue in
                    let proposedEndTime = newValue.addingTimeInterval(selectedDuration)
                    taskEndTime = proposedEndTime
                }
        }
    }
    
    private var endTimePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("終了日時")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            DatePicker("", selection: $taskEndTime, in: taskStartTime..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                )
                .padding(.horizontal, 16)
                .onChange(of: taskEndTime) { oldValue, newValue in
                    let newDuration = newValue.timeIntervalSince(taskStartTime)
                    if newDuration > 0 {
                        selectedDuration = newDuration
                    }
                }
        }
    }
    
    private var timeSummaryView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditMode ? "現在の設定" : "デフォルト設定")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
                Text("\(formatDateTime(taskStartTime)) 〜 \(formatDateTime(taskEndTime))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.1))
        )
        .padding(.horizontal, 16)
    }
    
    private var memoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（任意）")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            TextField("タスクの詳細をメモ...", text: $taskMemo, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                )
                .lineLimit(2...4)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var deleteButtonIfNeeded: some View {
        if isEditMode {
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(.body, design: .rounded))
                    Text("このタスクを削除")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.15))
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    
    private var fixedBottomButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: isEditMode ? saveExistingTask : saveTask) {
                Text("保存")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(saveButtonBackground)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .disabled(selectedCategory == nil)
        }
        .background(Color.black)
    }
    
    private var saveButtonBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                selectedCategory != nil ?
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private func saveTask() {
        guard let category = selectedCategory else {
            return
        }
        
        // Check premium limitation
        let canAdd = viewModel.canAddTask(for: viewModel.selectedDate)
        if !canAdd.allowed, let reason = canAdd.reason {
            premiumGateMessage = reason
            showingPremiumGate = true
            return
        }
        
        viewModel.addTimeBlock(
            title: category.name,
            startTime: taskStartTime,
            endTime: taskEndTime,
            category: category,
            notes: taskMemo,
            tags: []
        )
        
        // Dismiss the view
        DispatchQueue.main.async {
            self.isPresented = false
        }
    }
    
    private func saveExistingTask() {
        guard let category = selectedCategory,
              let block = existingBlock else {
            return
        }
        
        // Update block properties
        block.title = category.name
        block.startTime = taskStartTime
        block.endTime = taskEndTime
        block.category = category
        block.notes = taskMemo
        
        // Call edit callback
        onSave?(block)
        
        // Dismiss the view
        DispatchQueue.main.async {
            self.isPresented = false
        }
    }
    
    private func getMainCategories() -> [SDCategory] {
        let mainCategoryNames = [
            "仕事",        // Work
            "会議",        // Meeting
            "メール・連絡",  // Email
            "家事",        // Housework
            "買い物",      // Shopping
            "準備・身支度",  // Preparation
            "睡眠",        // Sleep
            "運動",        // Exercise
            "食事",        // Meals
            "休憩",        // Break
            "勉強",        // Study
            "娯楽",        // Entertainment
            "通勤",        // Commuting
            "外出",        // Going out
            "その他"       // Others
        ]
        
        return viewModel.getCategories().filter { category in
            mainCategoryNames.contains(category.name)
        }
    }
    
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var viewModel: SwiftDataTimeTrackingViewModel?
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            Group {
                if let viewModel = viewModel {
                    UnifiedTaskAddView(
                        viewModel: viewModel,
                        isPresented: $isPresented,
                        suggestedStartTime: Date(),
                        suggestedEndTime: Date().addingTimeInterval(3600)
                    )
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                viewModel = SwiftDataTimeTrackingViewModel(modelContext: modelContext)
            }
        }
    }
    
    return PreviewWrapper()
        .modelContainer(for: [SDTimeBlock.self, SDCategory.self, SDTag.self, SDTaskTemplate.self])
}