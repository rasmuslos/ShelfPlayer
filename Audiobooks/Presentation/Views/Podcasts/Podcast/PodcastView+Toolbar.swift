//
//  PodcastView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

extension PodcastView {
    struct ToolbarModifier: ViewModifier {
        let podcast: Podcast
        
        @Binding var navbarVisible: Bool
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(podcast.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(navbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navbarVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navbarVisible {
                            VStack {
                                Text(podcast.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(String(podcast.episodeCount) + " Episodes")
                                    .font(.caption2)
                                    .lineLimit(1)
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
        }
    }
}
