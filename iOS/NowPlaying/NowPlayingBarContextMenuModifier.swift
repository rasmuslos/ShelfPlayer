//
//  NowPlayingBarContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 10.04.24.
//

import SwiftUI
import Defaults
import SPBase
import SPPlayback

struct NowPlayingBarContextMenuModifier: ViewModifier {
    @Default(.skipBackwardsInterval) private var skipBackwardsInterval
    @Default(.skipForwardsInterval) private var skipForwardsInterval
    
    let item: PlayableItem
    
    @Binding var animateForwards: Bool
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() - Double(skipBackwardsInterval))
                } label: {
                    Label("backwards", systemImage: "gobackward.\(skipForwardsInterval)")
                }
                
                Button {
                    animateForwards.toggle()
                    AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                } label: {
                    Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                }
                
                Divider()
                
                Menu {
                    ChapterSelectMenu()
                } label: {
                    Label("chapters", systemImage: "list.dash")
                }
                
                Divider()
                
                SleepTimerButton()
                PlaybackSpeedButton()
                
                Divider()
                
                Button {
                    AudioPlayer.shared.stopPlayback()
                } label: {
                    Label("playback.stop", systemImage: "xmark")
                }
            } preview: {
                VStack(alignment: .leading) {
                    ItemImage(image: item.image)
                        .padding(.bottom, 10)
                    
                    Group {
                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                        } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(item.name)
                        .font(.headline)
                    
                    if let author = item.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 250)
                .padding()
            }
    }
}
