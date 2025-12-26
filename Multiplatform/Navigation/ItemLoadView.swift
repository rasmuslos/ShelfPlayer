//
//  ItemLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.01.25.
//

import OSLog
import SwiftUI
import ShelfPlayback

struct ItemLoadView: View {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ItemLoadView")
    
    @Environment(\.namespace) private var namespace
    
    let id: ItemIdentifier
    let zoom: Bool
    
    init(_ id: ItemIdentifier, zoom: Bool = false) {
        self.id = id
        self.zoom = zoom
    }
    
    @State private var item: Item? = nil
    @State private var failed = false
    
    var body: some View {
        Group {
            if let item {
                ItemView(item: item)
            } else {
                if failed {
                    ErrorView(itemID: id)
                        .refreshable {
                            load(refresh: true)
                        }
                } else {
                    LoadingView()
                        .task {
                            load(refresh: false)
                        }
                        .refreshable {
                            load(refresh: true)
                        }
                }
            }
        }
        .modify(if: zoom) {
            $0
                .navigationTransition(.zoom(sourceID: "item_\(id)", in: namespace!))
        }
    }
    
    private nonisolated func load(refresh: Bool) {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            if refresh {
                try? await ShelfPlayer.refreshItem(itemID: id)
            }
            
            do {
                let item = try await id.resolved
                
                await MainActor.withAnimation {
                    self.item = item
                }
            } catch {
                logger.info("Failed to load item \(id): \(error)")
                
                await MainActor.withAnimation {
                    failed = false
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ItemLoadView(.fixture)
}
#endif
