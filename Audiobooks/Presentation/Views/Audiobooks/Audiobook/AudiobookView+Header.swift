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
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryReader { reader in
                    let offset = reader.frame(in: .global).minY
                    
                    Color.clear
                        .onChange(of: offset) {
                            navbarVisible = offset < -300
                        }
                }
                .frame(height: 0)
                VStack {
                    ItemImage(image: audiobook.image)
                        .padding(.horizontal, 50)
                        .shadow(radius: 30)
                    
                    if let series = audiobook.series {
                        NavigationLink {
                            if seriesId == nil {
                                SeriesUnavailableView()
                            } else {
                                Text(seriesId!)
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
                                    Text(authorId)
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
                        Label("Listen", systemImage: "play.fill")
                    }
                    .buttonStyle(PlayNowButtonStyle(percentage: 0.5))
                }
            }
        }
    }
}
