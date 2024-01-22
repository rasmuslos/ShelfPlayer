//
//  PodcastView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

extension PodcastView {
    struct ToolbarModifier: ViewModifier {
        let podcast: Podcast
        
        @Binding var navigationBarVisible: Bool
        @Binding var backgroundColor: UIColor
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(podcast.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navigationBarVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navigationBarVisible {
                            VStack {
                                Text(podcast.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(String(podcast.episodeCount) + " Episodes")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                }
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            CustomBackButton(isLight: backgroundColor.isLight(), navigationBarVisible: $navigationBarVisible)
                        }
                    }
                }
        }
    }
}
