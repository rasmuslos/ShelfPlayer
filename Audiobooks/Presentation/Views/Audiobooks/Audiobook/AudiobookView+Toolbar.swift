//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        let audiobook: Audiobook
        
        @Binding var navbarVisible: Bool
        
        func body(content: Content) -> some View {
            content
                .toolbarBackground(navbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navbarVisible)
                .navigationTitle(audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navbarVisible {
                            VStack {
                                Text(audiobook.name)
                                    .font(.headline)
                                    .fontDesign(.serif)
                                    .lineLimit(1)
                                
                                if let author = audiobook.author {
                                    Text(author)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                        } else {
                            Text("")
                        }
                    }
                }
                .toolbar {
                    if !navbarVisible {
                        ToolbarItem(placement: .navigation) {
                            CustomBackButton(navbarVisible: $navbarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button {
                                
                            } label: {
                                Image(systemName: "arrow.down")
                            }
                            .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible))
                            Menu {
                                Label("Command", systemImage: "command")
                                Label("Command", systemImage: "command")
                                Label("Command", systemImage: "command")
                                Label("Command", systemImage: "command")
                            } label: {
                                Image(systemName: "ellipsis")
                                    .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible))
                            }
                        }
                    }
                }
        }
    }
}
