//
//  AudiobookRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI

struct AudiobookRow: View {
    let audiobook: Audiobook
    
    @State var bottomText: String?
    
    var body: some View {
        NavigationLink(
            destination: AudiobookView(audiobook: audiobook)) {
            HStack {
                ItemProgressImage(item: audiobook)
                    .frame(width: 85)
                
                VStack(alignment: .leading) {
                    let topText = getTopText()
                    if topText.count > 0 {
                        Text(topText.joined(separator: " • "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .fontDesign(.serif)
                        .lineLimit(1)
                    
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .imageScale(.large)
                                .font(.title3)
                            
                            if let bottomText = bottomText {
                                Text(bottomText)
                            } else {
                                Text("")
                                    .onAppear(perform: fetchRemainingTime)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 5)
            }
        }
    }
}

// MARK: Helper

extension AudiobookRow {
    private func getTopText() -> [String] {
        var parts = [String]()
        
        if let author = audiobook.author {
            parts.append(author)
        }
        if let released = audiobook.released {
            parts.append(String(released.get(.year)))
        }
        
        return parts
    }
    
    func fetchRemainingTime() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgress(audiobook: audiobook) {
                bottomText = progress.readableProgress(spaceConstrained: false)
            } else {
                bottomText = audiobook.duration.timeLeft(spaceConstrained: false)
            }
        }
    }
}
