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
    
    @Default(.enableConvenienceDownloads) private var enableConvenienceDownloads
    @Default(.enableListenNowDownloads) private var enableListenNowDownloads
    
    @State private var listenNowItems = [PlayableItem]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Menu {
                        ListenedTodayLabel.AdjustMenuInner()
                    } label: {
                        HStack(spacing: 12) {
                            ListenedTodayListRow()
                            
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .menuActionDismissBehavior(.disabled)
                    .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
                
                if listenNowItems.isEmpty {
                    if isLoading {
                        LoadingView.Inner()
                    } else {
                        EmptyCollectionView.Inner()
                    }
                } else {
                    Section("panel.listenNow") {
                        ForEach(listenNowItems) { item in
                            Button {
                                satellite.start(item.id)
                                satellite.dismissSheet()
                            } label: {
                                ItemCompactRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
                        }
                    }
                }
                
                if enableConvenienceDownloads {
                    Section {
                        Toggle("preferences.convenienceDownload.enableListenNowDownloads", systemImage: "arrow.down.square", isOn: $enableListenNowDownloads)
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
                await PersistenceManager.shared.listenNow.invalidate()
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
