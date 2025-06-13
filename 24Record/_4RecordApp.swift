//
//  _4RecordApp.swift
//  24Record
//
//  Created by 岡本竜弥 on 2025/06/10.
//

import SwiftUI
import SwiftData

@main
struct _4RecordApp: App {
    @StateObject private var dataController = DataController.shared
    @AppStorage("appTheme") private var appTheme: String = "system"
    @Environment(\.colorScheme) var systemColorScheme
    
    init() {
        // 日本語ロケール設定
        UserDefaults.standard.set(["ja"], forKey: "AppleLanguages")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataController.container)
                .preferredColorScheme(colorScheme)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .task {
                    // Migrate data from UserDefaults on first launch
                    await dataController.migrateFromUserDefaults()
                }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
