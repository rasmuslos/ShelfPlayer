//
//  AudiobookColumn.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookCover: View {
    let audiobook: Audiobook
    
    @State var bottomText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemProgressImage(item: audiobook)
            
            Text(bottomText)
                .font(.footnote)
                .lineLimit(1)
                .padding(.top, 4)
                .foregroundStyle(.secondary)
                .onAppear(perform: fetchRemainingTime)
        }
        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
    }
}

// MARK: Progress

extension AudiobookCover {
    func fetchRemainingTime() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgress(item: audiobook) {
                bottomText = progress.readableProgress()
            } else {
                bottomText = audiobook.duration.timeLeft()
            }
        }
    }
}
