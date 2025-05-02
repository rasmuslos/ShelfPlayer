//
//  ListenNowSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct ListenNowSheet: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.downloadListenNowItems) private var downloadListenNowItems
    
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("item.preferences.automaticDownload.enabled", systemImage: "arrow.down.to.line") {
                        downloadListenNowItems.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .symbolVariant(downloadListenNowItems ? .circle.fill : .circle)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            load()
        }
        .refreshable {
            load()
        }
        .onReceive(RFNotification[.playbackItemChanged].publisher()) { _ in
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
        connectionStore.libraries.reduce(0) { $0 + $1.value.count }
    }
    
    var body: some View {
        if totalLibraryCount > 1 {
            Button("panel.listenNow", systemImage: "play.rectangle.on.rectangle.fill") {
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
