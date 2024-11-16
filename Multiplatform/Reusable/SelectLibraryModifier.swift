//
//  LibrarySelectorModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct SelectLibraryModifier: ViewModifier {
    @Environment(\.libraries) private var libraries
    
    let isCompact: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                if isCompact {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            LibraryMenu(libraries: libraries) {
                                NotificationCenter.default.post(name: Self.changeLibraryNotification, object: nil, userInfo: [ "libraryID": $0.id ])
                            }
                            
                            Divider()
                            
                            Button {
                                NotificationCenter.default.post(name: SelectLibraryModifier.changeLibraryNotification, object: nil, userInfo: [
                                    "offline": true,
                                ])
                            } label: {
                                Label("offline.enable", systemImage: "network.slash")
                            }
                        } label: {
                            Label("library.change", systemImage: "books.vertical.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
    }
    
    static let changeLibraryNotification = Notification.Name("io.rfk.shelfplayer.library.change")
}

extension SelectLibraryModifier {
    struct LibraryMenu: View {
        let libraries: [Library]
        let callback: (Library) -> Void
        
        var body: some View {
            ForEach(libraries) { library in
                Button {
                    callback(library)
                } label: {
                    Label(library.name, systemImage: library.type == .audiobooks ? "headphones" : "antenna.radiowaves.left.and.right")
                }
            }
        }
    }
}
