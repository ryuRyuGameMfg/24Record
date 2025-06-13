//
//  ContentView.swift
//  24Record
//
//  Created by 岡本竜弥 on 2025/06/10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SwiftDataTimeTrackingViewModel?
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    MainView(viewModel: viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel = SwiftDataTimeTrackingViewModel(modelContext: modelContext)
                        }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                // Debug: Reset data button (only in debug builds)
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("リセット") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .font(.caption)
                }
                #endif
            }
        }
        .alert("データをリセット", isPresented: $showingResetAlert) {
            Button("リセット", role: .destructive) {
                DataController.shared.resetAllData()
                // ViewModelを再作成
                viewModel = SwiftDataTimeTrackingViewModel(modelContext: modelContext)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべてのデータがリセットされ、デフォルトのカテゴリが復元されます。この操作は取り消せません。")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SDTimeBlock.self, SDCategory.self, SDTag.self, SDTaskTemplate.self])
}
