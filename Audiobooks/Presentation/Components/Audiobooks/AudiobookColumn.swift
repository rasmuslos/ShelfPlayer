//
//  AudiobookColumn.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct AudiobookColumn: View {
    let audiobook: Audiobook
    
    @State var bottomText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemProgressImage(item: audiobook)
                .onAppear {
                    fetchRemainingTime()
                }
            
            if let bottomText = bottomText {
                Text(bottomText)
                    .font(.footnote)
                    .lineLimit(1)
                    .padding(.top, 4)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: Progress

extension AudiobookColumn {
    func fetchRemainingTime() {
        Task.detached {
            if bottomText == nil, let progress = await OfflineManager.shared.getProgress(audiobook: audiobook) {
                let remainingTime = max(progress.duration - progress.currentTime, 0)
                
                if remainingTime <= 5 {
                    bottomText = "100%"
                } else {
                    bottomText = formatTime(remainingTime)
                }
            } else {
                bottomText = formatTime(audiobook.duration)
            }
        }
    }
    
    func formatTime(_ time: Double) -> String {
        let (hours, minutes, seconds) = time.hoursMinutesSeconds()
        
        if hours != "00" {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)min \(seconds)s left"
        }
    }
}
