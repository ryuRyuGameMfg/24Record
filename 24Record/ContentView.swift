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
    
    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SDTimeBlock.self, SDCategory.self, SDTag.self, SDTaskTemplate.self])
}
