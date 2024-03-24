//
//  AudiobookView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPBase

extension AudiobookView {
    struct Header: View {
        @Environment(AudiobookViewModel.self) var viewModel
        
        var body: some View {
            ZStack(alignment: .top) {
                FullscreenBackground(threshold: -300, backgroundColor: .clear, navigationBarVisible: .init(get: { viewModel.navigationBarVisible }, set: { viewModel.navigationBarVisible = $0 }))
                    .frame(height: 0)
                
                VStack {
                    ItemImage(image: viewModel.audiobook.image)
                        .padding(.horizontal, 50)
                        .shadow(radius: 30)
                    
                    if let series = viewModel.audiobook.seriesName {
                        NavigationLink {
                            if let seriesId = viewModel.seriesId {
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
                        Text(viewModel.audiobook.name)
                            .font(.headline)
                            .fontDesign(.serif)
                            .multilineTextAlignment(.center)
                        
                        if let author = viewModel.audiobook.author {
                            NavigationLink {
                                if let authorId = viewModel.authorId {
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
                        
                        HStack(spacing: 3) {
                            if let narrator = viewModel.audiobook.narrator {
                                Text("audiobook.narrator \(narrator)")
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if viewModel.audiobook.explicit {
                                Image(systemName: "e.square.fill")
                            }
                            if viewModel.audiobook.abridged {
                                Image(systemName: "a.square.fill")
                            }
                            
                            Group {
                                if viewModel.audiobook.narrator != nil || viewModel.audiobook.explicit || viewModel.audiobook.abridged {
                                    Text(verbatim: " • ")
                                }
                                
                                Text(viewModel.audiobook.duration.numericDuration())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    }
                    .padding(.vertical, 5)
                    
                    PlayButton(item: viewModel.audiobook)
                }
            }
        }
    }
}
