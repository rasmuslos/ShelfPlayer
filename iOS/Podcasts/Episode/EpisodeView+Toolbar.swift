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
        
        init(episode: Episode, navigationBarVisible: Binding<Bool>, backgroundColor: Binding<UIColor>) {
            self.episode = episode
            
            _navigationBarVisible = navigationBarVisible
            _backgroundColor = backgroundColor
            
            offlineTracker = episode.offlineTracker
        }
        
        @Binding var navigationBarVisible: Bool
        @Binding var backgroundColor: UIColor
        
        func body(content: Content) -> some View {
            let isLight = backgroundColor.isLight()
            
            content
                .navigationTitle(episode.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(!navigationBarVisible)
                .toolbarBackground(navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            CustomBackButton(isLight: isLight, navigationBarVisible: .constant(false))
                        }
                        ToolbarItem(placement: .principal) {
                            Text(verbatim: "")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                if offlineTracker.status == .none {
                                    try await OfflineManager.shared.download(episodeId: episode.id, podcastId: episode.podcastId)
                                } else if offlineTracker.status == .downloaded {
                                    OfflineManager.shared.delete(episodeId: episode.id)
                                }
                            }
                        } label: {
                            switch offlineTracker.status {
                            case .none:
                                Image(systemName: "arrow.down")
                            case .working:
                                ProgressView()
                            case .downloaded:
                                Image(systemName: "xmark")
                            }
                        }
                        .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ToolbarProgressButton(item: episode)
                            .symbolVariant(.circle.fill)
                            .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                    }
                }
        }
    }
}
