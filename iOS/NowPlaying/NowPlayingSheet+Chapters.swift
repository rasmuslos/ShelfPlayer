//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

extension NowPlayingSheet {
    struct ChapterSheet: View {
        var body: some View {
            Group {
                if AudioPlayer.shared.chapters.count > 1 {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(AudioPlayer.shared.chapters) {
                                ChapterRow(chapter: $0)
                                    .id($0.id)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(AudioPlayer.shared.chapter?.id, anchor: .center)
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("chapters.empty")
                            .font(.headline.smallCaps())
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                HStack {
                    ItemImage(image: AudioPlayer.shared.item!.image)
                    
                    VStack(alignment: .leading) {
                        Text(AudioPlayer.shared.item!.name)
                            .font(.headline)
                            .fontDesign(AudioPlayer.shared.item as? Audiobook != nil ? .serif : .default)
                            .lineLimit(1)
                        
                        if let author = AudioPlayer.shared.item?.author {
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Group {
                            Text((AudioPlayer.shared.getItemDuration() - AudioPlayer.shared.getItemCurrentTime()).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)) + Text(verbatim: " ") + Text("time.left")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .frame(height: 100)
            }
        }
    }
}

// MARK: Chapter

extension NowPlayingSheet.ChapterSheet {
    struct ChapterRow: View {
        let chapter: PlayableItem.Chapter
        
        var active: Bool {
            chapter.start <= AudioPlayer.shared.getItemCurrentTime() && chapter.end > AudioPlayer.shared.getItemCurrentTime()
        }
        
        var body: some View {
            Button {
                AudioPlayer.shared.seek(to: chapter.start)
            } label: {
                VStack(alignment: .leading) {
                    HStack {
                        Text(chapter.title)
                            .bold(active)
                        
                        Spacer()
                        
                        if active {
                            Image(systemName: "waveform")
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }
                    }
                    .overlay(alignment: .leadingFirstTextBaseline) {
                        if active {
                            Circle()
                                .foregroundStyle(.gray.opacity(0.3))
                                .frame(width: 7, height: 7)
                                .offset(x: -13)
                                .transition(.opacity)
                        }
                    }
                    Text((chapter.end - chapter.start).hoursMinutesSecondsString(includeSeconds: true, includeLabels: false))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
