//
//  AudiobookView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import AudiobooksKit

extension AudiobookView {
    struct Header: View {
        let audiobook: Audiobook
        
        @Binding var authorId: String?
        @Binding var seriesId: String?
        @Binding var navigationBarVisible: Bool
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryRectangle(treshold: -250, backgroundColor: nil, navigationBarVisible: $navigationBarVisible)
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
                            .multilineTextAlignment(.center)
                        
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
                        
                        HStack(spacing: 3) {
                            if let narrator = audiobook.narrator {
                                Text("audiobook.narrtor \(narrator)")
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if audiobook.explicit {
                                Image(systemName: "e.square.fill")
                            }
                            if audiobook.abridged {
                                Image(systemName: "a.square.fill")
                            }
                        }
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    }
                    .padding(.vertical, 5)
                    
                    PlayButton(item: audiobook)
                }
            }
        }
    }
}
