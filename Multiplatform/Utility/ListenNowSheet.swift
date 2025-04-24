//
//  ListenNowSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import ShelfPlayerKit

struct ListenNowSheet: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var listenNowItems = [PlayableItem]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if listenNowItems.isEmpty {
                    if isLoading {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                } else {
                    List {
                        ForEach(listenNowItems) { item in
                            ItemCompactRow(item: item) {
                                satellite.start(item.id)
                                satellite.currentSheet = nil
                            }
                        }
                    }
                }
            }
            .navigationTitle("panel.listenNow")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }
    
    private nonisolated func load() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            let listenNowItems = await ShelfPlayerKit.listenNowItems
            
            await MainActor.run {
                isLoading = false
                self.listenNowItems = listenNowItems
            }
        }
    }
}

struct ListenNowSheetToggle: View {
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    private var totalLibraryCount: Int {
        connectionStore.libraries.map(\.value.count).reduce(0, +)
    }
    
    var body: some View {
        if totalLibraryCount > 1 {
            Button("panel.listenNow", systemImage: "play.square.stack.fill") {
                satellite.currentSheet = .listenNow
            }
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            ListenNowSheet()
        }
        .previewEnvironment()
}
#endif
