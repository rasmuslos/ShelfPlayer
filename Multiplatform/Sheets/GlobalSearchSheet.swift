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
    @State private var query: String = ""
    
    @State private var isLoading = false
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    if isLoading {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            ItemCompactRow(item: item) {
                                item.id.navigate()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("panel.search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .onChange(of: query) {
                loadItems()
            }
            .onReceive(RFNotification[.setGlobalSearch].publisher()) {
                query = $0
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
                
                let items = try await ShelfPlayerKit.globalSearch(query: query, includeOnlineSearchResults: true)
                
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
