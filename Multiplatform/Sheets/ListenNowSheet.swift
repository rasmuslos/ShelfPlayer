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
    
    @State private var listenNowItems = [PlayableItem]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: Text("abc")) {
                        Label("item.convenienceDownload", systemImage: "arrow.down.circle")
                    }
                    
                    #if DEBUG
                    NavigationLink(destination: Text(verbatim: "stats")) {
                        Label(String("Statistiken"), systemImage: "chart.line.uptrend.xyaxis")
                    }
                    #endif
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
        .onReceive(RFNotification[.playbackItemChanged].publisher()) { _ in
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
    
    @Default(.listenTimeTarget) private var listenTimeTarget
    
    var body: some View {
        Menu {
            ControlGroup {
                Button("action.decrease", systemImage: "minus") {
                    guard listenTimeTarget > 1 else {
                        return
                    }
                    
                    listenTimeTarget -= 1
                }
                
                Button("action.increase", systemImage: "plus") {
                    listenTimeTarget += 1
                }
            }
        } label: {
            ListenedTodayLabel()
        } primaryAction: {
            satellite.present(.listenNow)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuActionDismissBehavior(.disabled)
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
