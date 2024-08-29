//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPOfflineExtended

extension EpisodeView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let episode: Episode
        
        let navigationBarVisible: Bool
        let imageColors: ImageColors
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
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
                                FullscreenBackButton(isLight: imageColors.isLight, navigationBarVisible: false)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        DownloadButton(item: episode, downloadingLabel: false)
                            .labelStyle(.iconOnly)
                            .modifier(FullscreenToolbarModifier(isLight: imageColors.isLight, navigationBarVisible: navigationBarVisible))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressButton(item: episode)
                            .symbolVariant(.circle)
                            .modifier(FullscreenToolbarModifier(isLight: imageColors.isLight, navigationBarVisible: navigationBarVisible))
                    }
                }
        }
    }
}
