//
//  LibrarySelectorModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import SPBase

struct LibrarySelectorModifier: ViewModifier {
    @Environment(AvailableLibraries.self) var availableLibraries
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(availableLibraries.libraries) { library in
                            Button {
                                NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                                    "libraryId": library.id,
                                ])
                            } label: {
                                Label(library.name, systemImage: library.type == .audiobooks ? "book" : "waveform")
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                                "offline": true,
                            ])
                        } label: {
                            Label("offline.enable", systemImage: "network.slash")
                        }
                    } label: {
                        Label("tip.changeLibrary", systemImage: "books.vertical.fill")
                            .labelStyle(.iconOnly)
                    }
                    .popoverTip(SelectLibraryTip())
                }
            }
    }
}

#Preview {
    NavigationStack {
        Text(":)")
            .modifier(LibrarySelectorModifier())
            .environment(AvailableLibraries(libraries: [
                Library.audiobooksFixture,
                Library.audiobooksFixture,
                Library.audiobooksFixture,
                Library.audiobooksFixture,
            ]))
    }
}
