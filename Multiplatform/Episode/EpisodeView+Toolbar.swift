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
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let episode: Episode
        let offlineTracker: ItemOfflineTracker
        
        let navigationBarVisible: Bool
        let imageColors: Item.ImageColors
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
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
                .toolbarBackground(regularPresentation ? .automatic : navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navigationBarVisible && !regularPresentation)
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .principal) {
                            Text(verbatim: "")
                        }
                        
                        if !regularPresentation {
                            ToolbarItem(placement: .navigation) {
                                FullscreenBackButton(navigationBarVisible: false, isLight: imageColors.isLight)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        DownloadButton(item: episode, downloadingLabel: false)
                            .labelStyle(.iconOnly)
                            .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressButton(item: episode)
                            .symbolVariant(.circle)
                            .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                }
        }
    }
}
