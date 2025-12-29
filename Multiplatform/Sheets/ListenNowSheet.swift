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
    @Environment(OfflineMode.self) private var offlineMode
    
    @Default(.enableConvenienceDownloads) private var enableConvenienceDownloads
    @Default(.enableListenNowDownloads) private var enableListenNowDownloads
    
    @State private var listenNowItems = [PlayableItem]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                if !offlineMode.isEnabled {
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
            
            guard let listenNowItems = try? await PersistenceManager.shared.listenNow.current else {
                await MainActor.withAnimation {
                    listenNowItems = []
                }
                
                return
            }
            
            await MainActor.withAnimation {
                isLoading = false
                self.listenNowItems = listenNowItems
            }
        }
    }
}

struct ListenNowSheetToggle: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let width: CGFloat
    
    var body: some View {
        Menu {
            ListenedTodayLabel.AdjustMenuInner()
        } label: {
            ListenedTodayLabel()
                .contentShape(.rect)
                .frame(width: width)
        } primaryAction: {
            satellite.present(.listenNow)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuActionDismissBehavior(.disabled)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("panel.listenNow"))
        .matchedTransitionSource(id: "listen-now-sheet", in: namespace!)
    }
    
    @ToolbarContentBuilder
    static func toolbarItem() -> some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: .topBarTrailing) {
                ZStack {
                    ListenNowSheetToggle(width: 36)
                }
                .padding(4)
                .contentShape(.circle)
                .glassEffect(in: Circle())
            }
            .sharedBackgroundVisibility(.hidden)
            
            ToolbarSpacer(placement: .topBarTrailing)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                ListenNowSheetToggle(width: 26)
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

#Preview {
    NavigationStack {
        Text(verbatim: ":)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label(String(":)"), systemImage: "command")
                }
                
                ListenNowSheetToggle.toolbarItem()
            }
            .previewEnvironment()
    }
}
#endif
