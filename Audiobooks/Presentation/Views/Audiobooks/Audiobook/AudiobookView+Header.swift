//
//  AudiobookView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

extension AudiobookView {
    struct Header: View {
        let audiobook: Audiobook
        
        @Binding var authorId: String?
        @Binding var seriesId: String?
        @Binding var navbarVisible: Bool
        
        @State var progress: OfflineProgress?
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryReader { reader in
                    let offset = reader.frame(in: .global).minY
                    
                    Color.clear
                        .onChange(of: offset) {
                            navbarVisible = offset < -250
                        }
                }
                .frame(height: 0)
                VStack {
                    ItemImage(image: audiobook.image)
                        .padding(.horizontal, 50)
                        .shadow(radius: 30)
                    
                    if let series = audiobook.series.audiobookSeriesName ?? audiobook.series.name {
                        NavigationLink {
                            if let seriesId = seriesId {
                                SeriesLoadView(seriesId: seriesId)
                            } else {
                                SeriesUnavailableView()
                            }
                        } label: {
                            Text(series)
                                .font(.caption)
                                .bold()
                                .underline()
                                .lineLimit(1)
                                .padding(5)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(spacing: 0) {
                        Text(audiobook.name)
                            .font(.headline)
                            .fontDesign(.serif)
                            .lineLimit(1)
                        
                        if let author = audiobook.author {
                            NavigationLink {
                                if let authorId = authorId {
                                    AuthorLoadView(authorId: authorId)
                                } else {
                                    AuthorUnavailableView()
                                }
                            } label: {
                                Text(author)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .overlay(alignment: .trailingLastTextBaseline) {
                                        Image(systemName: "chevron.right.circle")
                                            .imageScale(.small)
                                            .offset(x: 17)
                                    }
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if let narrator = audiobook.narrator {
                            Text("Narrated by \(narrator)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Button {
                        
                    } label: {
                        if let progress = progress, progress.progress > 0 && progress.progress < 1 {
                            Label("Listen • \((progress.duration - progress.currentTime).timeLeft())", systemImage: "play.fill")
                        } else {
                            Label("Listen", systemImage: "play.fill")
                        }
                    }
                    .buttonStyle(PlayNowButtonStyle(percentage: progress?.progress ?? 0))
                    .onAppear {
                        if let progress = OfflineManager.shared.getProgress(audiobook: audiobook) {
                            self.progress = progress
                        }
                    }
                }
            }
        }
    }
}
