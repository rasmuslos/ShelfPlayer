//
//  GlobalSearchSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 04.06.25.
//

import SwiftUI
import ShelfPlayback

struct GlobalSearchSheet: View {
    @State private var items = [Item]()
    @State private var search: String = ""
    
    @State private var isLoading = false
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    if isLoading {
                        LoadingView.Inner()
                    } else {
                        EmptyCollectionView.Inner()
                    }
                } else {
                    ForEach(items) { item in
                        ItemCompactRow(item: item) {
                            item.id.navigate()
                        }
                    }
                }
            }
            .navigationTitle("panel.search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .onChange(of: search) {
                loadItems()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func loadItems() {
        task?.cancel()
        task = .detached {
            do {
                try await Task.sleep(for: .seconds(0.52))
                
                guard !Task.isCancelled else {
                    return
                }
                
                await MainActor.withAnimation {
                    self.isLoading = true
                }
                
                let items = try await ShelfPlayerKit.globalSearch(query: search, includeOnlineSearchResults: true)
                
                await MainActor.withAnimation {
                    self.items = items
                    self.isLoading = false
                }
            } catch {
                return
            }
        }
    }
}

#if DEBUG
#Preview {
    GlobalSearchSheet()
        .previewEnvironment()
}
#endif
