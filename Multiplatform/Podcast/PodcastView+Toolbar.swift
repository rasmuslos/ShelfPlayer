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
        let navigationBarVisible: Bool
        let imageColors: Item.ImageColors
        
        @State private var settingsSheetPresented = false
        
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
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            settingsSheetPresented.toggle()
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                        }
                        .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                }
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight)
                        }
                    }
                }
                .sheet(isPresented: $settingsSheetPresented) {
                    PodcastSettingsSheet(podcast: podcast)
                }
        }
    }
}
