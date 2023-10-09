//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

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
                            Text("")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            Button {
                                
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                            
                            let progress = OfflineManager.shared.getProgress(item: episode)?.progress ?? 0
                            Button {
                                Task {
                                    await episode.setProgress(finished: progress < 1)
                                }
                            } label: {
                                if progress >= 1 {
                                    Image(systemName: "minus.circle.fill")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: $navigationBarVisible))
                        }
                    }
                }
        }
    }
}
