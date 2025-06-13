import SwiftUI
import SwiftData

struct QuickActionButtonsView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @Binding var showingTaskAdd: Bool
    @State private var customizingButton: QuickActionButton?
    @State private var showingCustomizeSheet = false
    @State private var pressedButton: QuickActionButton?
    @State private var longPressTimer: Timer?
    
    // Default quick actions based on frequency
    @State private var quickActions: [QuickActionButton] = [
        QuickActionButton(id: UUID(), title: "仕事", icon: "briefcase.fill", color: .blue, categoryName: "仕事", duration: 3600),
        QuickActionButton(id: UUID(), title: "休憩", icon: "cup.and.saucer.fill", color: .green, categoryName: "個人", duration: 900),
        QuickActionButton(id: UUID(), title: "会議", icon: "person.3.fill", color: .purple, categoryName: "仕事", duration: 3600),
        QuickActionButton(id: UUID(), title: "運動", icon: "figure.run", color: .orange, categoryName: "運動", duration: 1800),
        QuickActionButton(id: UUID(), title: "食事", icon: "fork.knife", color: .red, categoryName: "食事", duration: 2700)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick action buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickActions) { action in
                        QuickActionButtonView(
                            action: action,
                            isPressed: pressedButton?.id == action.id,
                            onTap: {
                                handleQuickAction(action)
                            },
                            onLongPress: {
                                handleLongPress(action)
                            }
                        )
                    }
                    
                    // Add custom action button
                    AddCustomActionButton {
                        showingCustomizeSheet = true
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 80)
            
        }
        .sheet(isPresented: $showingCustomizeSheet) {
            CustomizeQuickActionSheet(
                action: customizingButton ?? QuickActionButton(
                    id: UUID(),
                    title: "",
                    icon: "star.fill",
                    color: .pink,
                    categoryName: "",
                    duration: 3600
                ),
                isNewAction: customizingButton == nil,
                onSave: { updatedAction in
                    if let index = quickActions.firstIndex(where: { $0.id == updatedAction.id }) {
                        quickActions[index] = updatedAction
                    } else {
                        quickActions.append(updatedAction)
                    }
                    saveQuickActions()
                },
                onDelete: {
                    if let action = customizingButton {
                        quickActions.removeAll { $0.id == action.id }
                        saveQuickActions()
                    }
                }
            )
        }
        .onAppear {
            loadQuickActions()
            updateSuggestedActions()
        }
    }
    
    // MARK: - Quick Action Handling
    private func handleQuickAction(_ action: QuickActionButton) {
        // Create a new task with the quick action settings
        let now = Date()
        let endTime = now.addingTimeInterval(action.duration)
        
        // Find or create category
        if let category = viewModel.getCategories().first(where: { $0.name == action.categoryName }) {
            viewModel.addTimeBlock(
                title: action.title,
                startTime: now,
                endTime: endTime,
                category: category,
                notes: "クイックアクションから追加"
            )
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleLongPress(_ action: QuickActionButton) {
        customizingButton = action
        showingCustomizeSheet = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Suggested Actions
    private func getSuggestedAction() -> QuickActionButton? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Time-based suggestions
        switch hour {
        case 7...9:
            return QuickActionButton(
                id: UUID(),
                title: "朝食",
                icon: "sun.max.fill",
                color: .orange,
                categoryName: "食事",
                duration: 1800
            )
        case 12...13:
            return QuickActionButton(
                id: UUID(),
                title: "昼食",
                icon: "fork.knife",
                color: .green,
                categoryName: "食事",
                duration: 2700
            )
        case 18...19:
            return QuickActionButton(
                id: UUID(),
                title: "夕食",
                icon: "moon.fill",
                color: .purple,
                categoryName: "食事",
                duration: 3600
            )
        default:
            // Return most frequent action for this time
            return getMostFrequentAction(for: hour)
        }
    }
    
    private func getMostFrequentAction(for hour: Int) -> QuickActionButton? {
        // Analyze past patterns and return the most frequent action
        // This would integrate with the task history
        let recentBlocks = viewModel.getTimeBlocks(for: Date()).filter { block in
            let blockHour = Calendar.current.component(.hour, from: block.startTime)
            return abs(blockHour - hour) <= 1
        }
        
        // Find most common category
        let categoryCounts = recentBlocks.reduce(into: [String: Int]()) { counts, block in
            let categoryName = block.category?.name ?? "その他"
            counts[categoryName, default: 0] += 1
        }
        
        if let mostFrequent = categoryCounts.max(by: { $0.value < $1.value }) {
            return quickActions.first { $0.categoryName == mostFrequent.key }
        }
        
        return nil
    }
    
    private func updateSuggestedActions() {
        // Analyze user patterns and update quick actions
        let allBlocks = viewModel.getAllTimeBlocks()
        
        // Count frequency of categories
        let categoryCounts = allBlocks.reduce(into: [String: Int]()) { counts, block in
            let categoryName = block.category?.name ?? "その他"
            counts[categoryName, default: 0] += 1
        }
        
        // Update quick actions based on frequency
        let topCategories = categoryCounts.sorted { $0.value > $1.value }.prefix(5)
        
        // Update existing quick actions or add new ones
        for (index, (categoryName, _)) in topCategories.enumerated() {
            if let category = viewModel.getCategories().first(where: { $0.name == categoryName }) {
                if index < quickActions.count {
                    quickActions[index].categoryName = categoryName
                    quickActions[index].color = Color(hex: category.colorHex) ?? .blue
                }
            }
        }
    }
    
    // MARK: - Persistence
    private func saveQuickActions() {
        // Save to UserDefaults or SwiftData
        if let encoded = try? JSONEncoder().encode(quickActions) {
            UserDefaults.standard.set(encoded, forKey: "quickActions")
        }
    }
    
    private func loadQuickActions() {
        if let data = UserDefaults.standard.data(forKey: "quickActions"),
           let decoded = try? JSONDecoder().decode([QuickActionButton].self, from: data) {
            quickActions = decoded
        }
    }
}

// MARK: - Quick Action Button Model
struct QuickActionButton: Identifiable, Codable {
    let id: UUID
    var title: String
    var icon: String
    var color: Color
    var categoryName: String
    var duration: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case id, title, icon, categoryName, duration
        case colorHex
    }
    
    init(id: UUID, title: String, icon: String, color: Color, categoryName: String, duration: TimeInterval) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.categoryName = categoryName
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex) ?? .blue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(icon, forKey: .icon)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encode(duration, forKey: .duration)
        try container.encode(color.toHex() ?? "#0000FF", forKey: .colorHex)
    }
}

// MARK: - Quick Action Button View
struct QuickActionButtonView: View {
    let action: QuickActionButton
    let isPressed: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [action.color, action.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .shadow(
                            color: action.color.opacity(0.5),
                            radius: isPressed ? 12 : 8,
                            x: 0,
                            y: isPressed ? 6 : 4
                        )
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                
                Text(action.title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Voice Input Button
struct VoiceInputButton: View {
    let onTap: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .shadow(
                            color: .red.opacity(0.5),
                            radius: isAnimating ? 15 : 10,
                            x: 0,
                            y: isAnimating ? 8 : 5
                        )
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                Text("音声")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Add Custom Action Button
struct AddCustomActionButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Text("追加")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Suggested Action View
struct SuggestedActionView: View {
    let action: QuickActionButton
    let onAccept: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.yellow)
            
            Text("おすすめ: \(action.title)")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: onAccept) {
                Text("追加")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(action.color)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Customize Quick Action Sheet
struct CustomizeQuickActionSheet: View {
    @State var action: QuickActionButton
    let isNewAction: Bool
    let onSave: (QuickActionButton) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    let availableIcons = [
        "briefcase.fill", "cup.and.saucer.fill", "person.3.fill",
        "figure.run", "fork.knife", "book.fill", "gamecontroller.fill",
        "music.note", "cart.fill", "house.fill", "car.fill",
        "airplane", "bed.double.fill", "tv.fill", "phone.fill"
    ]
    
    let availableColors: [Color] = [
        .blue, .green, .purple, .orange, .red,
        .pink, .yellow, .teal, .indigo, .brown
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("アクション設定") {
                    TextField("タイトル", text: $action.title)
                    
                    Picker("カテゴリ", selection: $action.categoryName) {
                        Text("仕事").tag("仕事")
                        Text("個人").tag("個人")
                        Text("運動").tag("運動")
                        Text("食事").tag("食事")
                        Text("勉強").tag("勉強")
                        Text("睡眠").tag("睡眠")
                    }
                    
                    // Duration picker
                    HStack {
                        Text("時間")
                        Spacer()
                        Text(formatDuration(action.duration))
                            .foregroundColor(.gray)
                    }
                    .overlay(
                        Slider(
                            value: Binding(
                                get: { action.duration / 60 },
                                set: { action.duration = $0 * 60 }
                            ),
                            in: 5...120,
                            step: 5
                        )
                        .opacity(0.01)
                    )
                }
                
                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                action.icon = icon
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(action.icon == icon ? action.color : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(action.icon == icon ? .white : .gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                action.color = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: action.color == color ? 3 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if !isNewAction {
                    Section {
                        Button(action: {
                            onDelete()
                            dismiss()
                        }) {
                            Text("削除")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isNewAction ? "新規アクション" : "アクション編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(action)
                        dismiss()
                    }
                    .disabled(action.title.isEmpty || action.categoryName.isEmpty)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)分"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)時間"
            } else {
                return "\(hours)時間\(remainingMinutes)分"
            }
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
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
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}