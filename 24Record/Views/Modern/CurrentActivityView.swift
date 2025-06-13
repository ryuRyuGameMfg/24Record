import SwiftUI
import SwiftData

struct CurrentActivityView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @State private var currentActivity: SDTimeBlock?
    @State private var isRecording = false
    @State private var recordingStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingQuickRecord = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isRecording, let activity = currentActivity {
                // Recording in progress
                HStack(spacing: 16) {
                    // Activity info
                    HStack(spacing: 12) {
                        // Animated recording indicator
                        RecordingIndicator()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(formatElapsedTime(elapsedTime))
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Stop button
                        Button(action: stopRecording) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 32, height: 32)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(white: 0.15),
                                        Color(white: 0.10)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.6), Color.red.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Quick switch button
                    Button(action: { showingQuickRecord = true }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(white: 0.1))
                            )
                    }
                }
            } else {
                // Not recording - show start button
                Button(action: { showingQuickRecord = true }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Text("活動を記録")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(white: 0.12),
                                        Color(white: 0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .sheet(isPresented: $showingQuickRecord) {
            QuickRecordView(
                viewModel: viewModel,
                currentActivity: currentActivity,
                onStart: { activity in
                    if isRecording {
                        stopRecording()
                    }
                    startRecording(activity: activity)
                }
            )
        }
        .onAppear {
            checkForActiveRecording()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isRecording {
                elapsedTime = Date().timeIntervalSince(recordingStartTime)
            }
        }
    }
    
    private func checkForActiveRecording() {
        // Check if there's an active recording from previous session
        let recentBlocks = viewModel.getTimeBlocks(for: Date())
        if let lastBlock = recentBlocks.last,
           !lastBlock.isCompleted,
           lastBlock.endTime > Date() {
            currentActivity = lastBlock
            isRecording = true
            recordingStartTime = lastBlock.startTime
            elapsedTime = Date().timeIntervalSince(recordingStartTime)
        }
    }
    
    private func startRecording(activity: SDTimeBlock) {
        currentActivity = activity
        isRecording = true
        recordingStartTime = Date()
        elapsedTime = 0
        
        // Add the activity to timeline
        viewModel.addTimeBlock(
            title: activity.title,
            startTime: recordingStartTime,
            endTime: recordingStartTime.addingTimeInterval(3600), // Temporary end time
            category: activity.category!,
            notes: "記録中..."
        )
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func stopRecording() {
        guard let activity = currentActivity else { return }
        
        let endTime = Date()
        
        // Update the time block with actual end time
        if let lastBlock = viewModel.getTimeBlocks(for: Date()).last {
            viewModel.updateTimeBlock(lastBlock, startTime: recordingStartTime, endTime: endTime)
        }
        
        // Reset state
        currentActivity = nil
        isRecording = false
        elapsedTime = 0
        
        // Success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Recording Indicator
struct RecordingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Quick Record View
struct QuickRecordView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    let currentActivity: SDTimeBlock?
    let onStart: (SDTimeBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: SDCategory?
    @State private var activityTitle = ""
    @State private var showingCustomInput = false
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recent activities
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近の活動")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            // Get recent unique activities
                            ForEach(getRecentActivities(), id: \.id) { activity in
                                QuickActivityButton(
                                    activity: activity,
                                    isActive: currentActivity?.title == activity.title,
                                    onTap: {
                                        onStart(activity)
                                        dismiss()
                                    }
                                )
                            }
                            
                            // Custom activity button
                            Button(action: {
                                showingCustomInput = true
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(.title3, design: .rounded))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("新しい活動")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(white: 0.08))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("活動を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomInput) {
                CustomActivityInputView(
                    viewModel: viewModel,
                    onSave: { title, category in
                        let newActivity = SDTimeBlock(
                            title: title,
                            startTime: Date(),
                            endTime: Date().addingTimeInterval(3600),
                            category: category,
                            notes: "",
                            isCompleted: false
                        )
                        onStart(newActivity)
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            // Remove AI functionality
        }
    }
    
    private func getRecentActivities() -> [SDTimeBlock] {
        let recentBlocks = viewModel.getAllTimeBlocks()
            .sorted { $0.startTime > $1.startTime }
            .prefix(10)
        
        // Remove duplicates by title
        var uniqueTitles = Set<String>()
        var uniqueBlocks: [SDTimeBlock] = []
        
        for block in recentBlocks {
            if !uniqueTitles.contains(block.title) {
                uniqueTitles.insert(block.title)
                uniqueBlocks.append(block)
            }
        }
        
        return uniqueBlocks
    }
}

// MARK: - Quick Activity Button
struct QuickActivityButton: View {
    let activity: SDTimeBlock
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [activity.color, activity.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: activity.category?.icon ?? "circle")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(activity.category?.name ?? "")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isActive {
                    RecordingIndicator()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.red.opacity(0.1) : Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isActive ? Color.red.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Activity Input View
struct CustomActivityInputView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    let onSave: (String, SDCategory) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var activityTitle = ""
    @State private var selectedCategory: SDCategory?
    
    var body: some View {
        NavigationView {
            Form {
                Section("新しい活動") {
                    TextField("活動名", text: $activityTitle)
                        .onChange(of: activityTitle) { oldValue, newValue in
                            // Remove AI category prediction
                        }
                    
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(viewModel.getCategories()) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                            }
                            .tag(Optional(category))
                        }
                    }
                }
            }
            .navigationTitle("新しい活動")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("開始") {
                        if let category = selectedCategory ?? viewModel.getCategories().first {
                            onSave(activityTitle, category)
                        }
                    }
                    .disabled(activityTitle.isEmpty)
                }
            }
        }
        .onAppear {
            selectedCategory = viewModel.getCategories().first
        }
    }
}