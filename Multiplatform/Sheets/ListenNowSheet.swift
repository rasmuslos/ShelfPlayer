//
//  ListenNowSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import ShelfPlayback

struct ListenNowSheet: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var listenNowItems = [PlayableItem]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ListenedTodayListRow()
                }
                
                if listenNowItems.isEmpty {
                    if isLoading {
                        LoadingView.Inner()
                    } else {
                        EmptyCollectionView.Inner()
                    }
                } else {
                    ForEach(listenNowItems) { item in
                        ItemCompactRow(item: item) {
                            satellite.start(item.id)
                            satellite.dismissSheet()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            load(refresh: false)
        }
        .refreshable {
            load(refresh: true)
        }
        .onReceive(RFNotification[.listenNowItemsChanged].publisher()) { _ in
            load(refresh: false)
        }
    }
    
    private nonisolated func load(refresh: Bool) {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            if refresh {
                await ListenNowCache.shared.invalidate()
            }
            
            let listenNowItems = await ShelfPlayerKit.listenNowItems
            
            await MainActor.withAnimation {
                isLoading = false
                self.listenNowItems = listenNowItems
            }
        }
    }
}

struct ListenNowSheetToggle: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        Menu {
            ListenedTodayLabel.AdjustMenuInner()
        } label: {
            ListenedTodayLabel()
                .frame(width: 22)
        } primaryAction: {
            satellite.present(.listenNow)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuActionDismissBehavior(.disabled)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("panel.listenNow"))
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
