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
                            ForEach(libraries) { library in
                                Button {
                                    NotificationCenter.default.post(name: Self.changeLibraryNotification, object: nil, userInfo: [
                                        "libraryID": library.id,
                                    ])
                                } label: {
                                    Label(library.name, systemImage: library.type == .audiobooks ? "book" : "waveform")
                                }
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
                            Label("tip.changeLibrary", systemImage: "books.vertical.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
    }
    
    static let changeLibraryNotification = Notification.Name("io.rfk.shelfplayer.library.change")
}
