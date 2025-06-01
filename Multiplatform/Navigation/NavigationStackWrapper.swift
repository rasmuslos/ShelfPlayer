//
//  NavigationSTackWrapper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 11.01.25.
//

import SwiftUI
import ShelfPlayback

struct NavigationStackWrapper<Content: View>: View {
    let tab: TabValue
    
    @ViewBuilder var content: () -> Content
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: ItemLoadDestination.self) { destination in
                    ItemLoadView(destination.itemID)
                }
                .onReceive(RFNotification[._navigate].publisher()) {
                    let libraryID: String?
                    
                    if case .audiobookLibrary(let library) = tab {
                        libraryID = library.id
                    } else if case .podcastLibrary(let library) = tab {
                        libraryID = library.id
                    } else {
                        libraryID = nil
                    }
                    
                    guard let libraryID, $0.libraryID == libraryID else {
                        return
                    }
                    
                    path.append(ItemLoadDestination(itemID: $0))
                }
        }
        .environment(\.library, tab.library)
    }
    
    struct ItemLoadDestination: Hashable {
        let itemID: ItemIdentifier
    }
}
