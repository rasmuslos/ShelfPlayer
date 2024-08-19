//
//  PodcastView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

extension PodcastView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let podcast: Podcast
        let navigationBarVisible: Bool
        let imageColors: Item.ImageColors
        
        @State private var settingsSheetPresented = false
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(podcast.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(regularPresentation ? .automatic : navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navigationBarVisible && !regularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navigationBarVisible {
                            VStack {
                                Text(podcast.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("\(podcast.episodeCount) episodes")
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
                            Label("more", systemImage: "ellipsis")
                                .labelStyle(.iconOnly)
                        }
                        .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: imageColors.isLight))
                    }
                }
                .toolbar {
                    if !navigationBarVisible && !regularPresentation {
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
