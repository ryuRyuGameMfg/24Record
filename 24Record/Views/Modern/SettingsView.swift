import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var viewModel: SwiftDataTimeTrackingViewModel
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var showingRoutineSettings = false
    @State private var showingPremiumSubscription = false
    @State private var showingResetAlert = false
    @State private var showingClearTasksAlert = false
    @State private var showingAbout = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Premium section
                        premiumSection
                        
                        // General settings
                        generalSettingsSection
                        
                        // Data management
                        dataManagementSection
                        
                        // About section
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.white)
        }
        .sheet(isPresented: $showingRoutineSettings) {
            DailyRoutineSettingsView()
        }
        .sheet(isPresented: $showingPremiumSubscription) {
            PremiumSubscriptionView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("タスクデータをクリア", isPresented: $showingClearTasksAlert) {
            Button("クリア", role: .destructive) {
                clearTasksOnly()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべてのタスクデータが削除されます。カテゴリや設定は保持されます。この操作は取り消せません。")
        }
        .alert("データをリセット", isPresented: $showingResetAlert) {
            Button("リセット", role: .destructive) {
                DataController.shared.resetAllData()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべてのデータがリセットされ、デフォルトのカテゴリが復元されます。この操作は取り消せません。")
        }
    }
    
    private var premiumSection: some View {
        VStack(spacing: 16) {
            if storeManager.isPremium {
                // Premium user
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            Text("Premium")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Text("すべての機能をご利用いただけます")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.1), .orange.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            } else {
                // Free user - upgrade prompt
                Button(action: {
                    showingPremiumSubscription = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.pink)
                                    .font(.title2)
                                Text("Premiumにアップグレード")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            Text("無制限のタスク作成と高度な分析機能")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.1), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.pink.opacity(0.5), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
    
    private var generalSettingsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "一般設定")
            
            VStack(spacing: 1) {
                // Theme setting
                SettingsRow(
                    icon: "paintbrush.fill",
                    title: "テーマ",
                    subtitle: themeDisplayName,
                    action: {}
                ) {
                    Menu(themeDisplayName) {
                        Button("システム") { appTheme = "system" }
                        Button("ライト") { appTheme = "light" }
                        Button("ダーク") { appTheme = "dark" }
                    }
                    .foregroundColor(.pink)
                    .font(.system(.caption, design: .rounded))
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Week start setting
                SettingsRow(
                    icon: "calendar",
                    title: "週の開始",
                    subtitle: weekStartsOnMonday ? "月曜日" : "日曜日",
                    action: {}
                ) {
                    Toggle("", isOn: $weekStartsOnMonday)
                        .labelsHidden()
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Notifications setting
                SettingsRow(
                    icon: "bell.fill",
                    title: "通知",
                    subtitle: notificationsEnabled ? "有効" : "無効",
                    action: {}
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Routine settings
                SettingsRow(
                    icon: "clock.fill",
                    title: "ルーティン設定",
                    subtitle: "起床・就寝時間、固定タスク",
                    action: {
                        showingRoutineSettings = true
                    }
                ) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
            )
        }
    }
    
    private var dataManagementSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "データ管理")
            
            VStack(spacing: 1) {
                // Export data (Premium only)
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "データをエクスポート",
                    subtitle: storeManager.isPremium ? "CSV形式で出力" : "Premium機能",
                    action: storeManager.isPremium ? exportData : {
                        showingPremiumSubscription = true
                    }
                ) {
                    if storeManager.isPremium {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Clear tasks only
                SettingsRow(
                    icon: "clock.badge.xmark.fill",
                    title: "タスクデータをクリア",
                    subtitle: "タスクのみを削除（設定は保持）",
                    action: {
                        showingClearTasksAlert = true
                    }
                ) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Reset all data
                SettingsRow(
                    icon: "trash.fill",
                    title: "すべてのデータをリセット",
                    subtitle: "すべてのデータを削除",
                    action: {
                        showingResetAlert = true
                    }
                ) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "情報")
            
            VStack(spacing: 1) {
                // App version
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "バージョン",
                    subtitle: "1.0.0",
                    action: {}
                ) {
                    EmptyView()
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // About
                SettingsRow(
                    icon: "heart.fill",
                    title: "このアプリについて",
                    subtitle: "開発者情報・ライセンス",
                    action: {
                        showingAbout = true
                    }
                ) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
            )
        }
    }
    
    private var themeDisplayName: String {
        switch appTheme {
        case "light": return "ライト"
        case "dark": return "ダーク"
        default: return "システム"
        }
    }
    
    private func exportData() {
        // TODO: Implement data export functionality
        print("Export data functionality to be implemented")
    }
    
    private func clearTasksOnly() {
        // Clear only task data, preserve categories and settings
        viewModel.clearAllTasks()
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let trailing: () -> Content
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.pink)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                trailing()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App icon and info
                    VStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                        
                        Text("24Record")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("時間を記録し、生活を改善するためのアプリです")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Developer info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("開発者")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("岡本竜弥")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("主な機能")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "clock", text: "時間の記録とタイムライン表示")
                            FeatureRow(icon: "chart.bar", text: "詳細な分析とレポート")
                            FeatureRow(icon: "tag", text: "カテゴリとタグによる分類")
                            FeatureRow(icon: "repeat", text: "ルーティンタスクの自動化")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .background(Color.black)
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.pink)
                .frame(width: 20)
            
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var viewModel: SwiftDataTimeTrackingViewModel?
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            Group {
                if let viewModel = viewModel {
                    SettingsView(viewModel: viewModel)
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