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
        let item: PlayableItem
        let chapters = AudioPlayer.shared.chapters
        
        let duration = AudioPlayer.shared.getDuration()
        @State var currentTime: Double = AudioPlayer.shared.getCurrentTime()
        
        var body: some View {
            Group {
                if chapters.count > 1 {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(chapters) {
                                ChapterRow(chapter: $0, active: $0.start <= currentTime && $0.end > currentTime)
                                    .id($0.id)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(AudioPlayer.shared.getChapter()?.id, anchor: .center)
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
                    ItemImage(image: item.image)
                    
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                            .fontDesign(item as? Audiobook != nil ? .serif : .default)
                            .lineLimit(1)
                        
                        if let author = item.author {
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Group {
                            Text((duration - currentTime).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)) + Text(verbatim: " ") + Text("time.left")
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
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.currentTimeChangedNotification), perform: { _ in
                withAnimation {
                    currentTime = AudioPlayer.shared.getCurrentTime()
                }
            })
        }
    }
}

// MARK: Chapter

extension NowPlayingSheet.ChapterSheet {
    struct ChapterRow: View {
        let chapter: PlayableItem.Chapter
        let active: Bool
        
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

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            NowPlayingSheet.ChapterSheet(item: Audiobook.fixture)
        }
}
