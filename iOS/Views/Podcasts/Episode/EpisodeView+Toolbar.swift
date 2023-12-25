//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import AudiobooksKit

extension EpisodeView {
    struct ToolbarModifier: ViewModifier {
        let episode: Episode
        
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
                        HStack {
                            Button {
                                Task {
                                    if episode.offline == .none {
                                        try! await OfflineManager.shared.downloadEpisode(episode)
                                    } else if episode.offline == .downloaded {
                                        try! OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                                    }
                                }
                            } label: {
                                switch episode.offline {
                                case .none:
                                    Image(systemName: "arrow.down")
                                case .working:
                                    ProgressView()
                                case .downloaded:
                                    Image(systemName: "xmark")
                                }
                            }
                            .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                            
                            ToolbarProgressButton(item: episode)
                                .symbolVariant(.circle.fill)
                                .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                        }
                    }
                }
        }
    }
}
