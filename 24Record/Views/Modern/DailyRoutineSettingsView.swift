import SwiftUI

// RoutineTask structure for managing routine tasks
struct RoutineTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var categoryName: String
    var isEnabled: Bool = true
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

struct DailyRoutineSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = DailyRoutineSettings.shared
    @State private var routineTasks: [RoutineTask] = []
    @State private var showingAddRoutine = false
    @State private var editingRoutine: RoutineTask?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        Toggle("毎日のルーティンを有効にする", isOn: $settings.isRoutineEnabled)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(white: 0.1))
                    
                    Section(header: Text("基本設定").foregroundColor(.gray)) {
                        DatePicker(
                            "起床時間",
                            selection: $settings.wakeUpTime,
                            displayedComponents: .hourAndMinute
                        )
                        .foregroundColor(.white)
                        
                        DatePicker(
                            "就寝時間",
                            selection: $settings.bedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color(white: 0.1))
                    
                    Section(header: 
                        HStack {
                            Text("固定ルーティン")
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                showingAddRoutine = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.pink)
                            }
                        }
                    ) {
                        if routineTasks.isEmpty {
                            Text("ルーティンタスクがありません")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(routineTasks) { routine in
                                RoutineTaskRow(
                                    routine: routine,
                                    onEdit: {
                                        editingRoutine = routine
                                    },
                                    onDelete: {
                                        deleteRoutine(routine)
                                    }
                                )
                            }
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ルーティン設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineTaskView { newRoutine in
                routineTasks.append(newRoutine)
            }
        }
        .sheet(item: $editingRoutine) { routine in
            EditRoutineTaskView(routine: routine) { updatedRoutine in
                if let index = routineTasks.firstIndex(where: { $0.id == routine.id }) {
                    routineTasks[index] = updatedRoutine
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        // Routine tasks are loaded from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "routineTasks"),
           let tasks = try? JSONDecoder().decode([RoutineTask].self, from: data) {
            routineTasks = tasks
        }
    }
    
    private func saveSettings() {
        // Save routine tasks to UserDefaults
        if let data = try? JSONEncoder().encode(routineTasks) {
            UserDefaults.standard.set(data, forKey: "routineTasks")
        }
    }
    
    private func deleteRoutine(_ routine: RoutineTask) {
        routineTasks.removeAll { $0.id == routine.id }
    }
}

// MARK: - Routine Task Row
struct RoutineTaskRow: View {
    let routine: RoutineTask
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.body)
                    .foregroundColor(.white)
                
                HStack {
                    Text(timeText)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(routine.categoryName)
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startTime = formatter.string(from: routine.startTime)
        let endTime = formatter.string(from: routine.endTime)
        
        return "\(startTime)〜\(endTime)"
    }
}

// MARK: - Add Routine Task View
struct AddRoutineTaskView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (RoutineTask) -> Void
    
    @State private var title = ""
    @State private var categoryName = "仕事"
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    let categories = ["仕事", "個人", "運動", "食事", "勉強", "睡眠"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("タスク情報")) {
                    TextField("タイトル", text: $title)
                    
                    Picker("カテゴリー", selection: $categoryName) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("終了時間", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("ルーティンタスクを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let newRoutine = RoutineTask(
                            title: title,
                            startTime: startTime,
                            endTime: endTime,
                            categoryName: categoryName
                        )
                        onSave(newRoutine)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Routine Task View
struct EditRoutineTaskView: View {
    @Environment(\.dismiss) var dismiss
    let routine: RoutineTask
    let onSave: (RoutineTask) -> Void
    
    @State private var title: String
    @State private var categoryName: String
    @State private var startTime: Date
    @State private var endTime: Date
    
    let categories = ["仕事", "個人", "運動", "食事", "勉強", "睡眠"]
    
    init(routine: RoutineTask, onSave: @escaping (RoutineTask) -> Void) {
        self.routine = routine
        self.onSave = onSave
        self._title = State(initialValue: routine.title)
        self._categoryName = State(initialValue: routine.categoryName)
        self._startTime = State(initialValue: routine.startTime)
        self._endTime = State(initialValue: routine.endTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("タスク情報")) {
                    TextField("タイトル", text: $title)
                    
                    Picker("カテゴリー", selection: $categoryName) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("終了時間", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("ルーティンタスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updatedRoutine = routine
                        updatedRoutine.title = title
                        updatedRoutine.categoryName = categoryName
                        updatedRoutine.startTime = startTime
                        updatedRoutine.endTime = endTime
                        onSave(updatedRoutine)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}