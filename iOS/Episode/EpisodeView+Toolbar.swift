//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

extension EpisodeView {
    struct ToolbarModifier: ViewModifier {
        let episode: Episode
        let offlineTracker: ItemOfflineTracker
        
        let navigationBarVisible: Bool
        let imageColors: Item.ImageColors
        
        init(episode: Episode, navigationBarVisible: Bool, imageColors: Item.ImageColors) {
            self.episode = episode
            self.navigationBarVisible = navigationBarVisible
            self.imageColors = imageColors
            
            offlineTracker = episode.offlineTracker
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(episode.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navigationBarVisible)
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(navigationBarVisible: false, isLight: imageColors.isLight)
                        }
                        ToolbarItem(placement: .principal) {
                            Text(verbatim: "")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        DownloadButton(item: episode, downloadingLabel: false)
                            .labelStyle(.iconOnly)
                            .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressButton(item: episode)
                            .symbolVariant(.circle.fill)
                            .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                }
        }
    }
}
