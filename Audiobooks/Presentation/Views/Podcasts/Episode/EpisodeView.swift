//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeView: View {
    let episode: Episode
    
    var body: some View {
        ScrollView {
            Header(episode: episode)
            
            if let descriptionText = episode.descriptionText {
                Text(descriptionText)
                    .padding()
            }
        }
        .ignoresSafeArea(edges: .all)
        .navigationTitle(episode.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                CustomBackButton(navbarVisible: .constant(false))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                }
                .modifier(FullscreenToolbarModifier(navbarVisible: .constant(false)))
            }
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeView(episode: Episode.fixture)
    }
}
