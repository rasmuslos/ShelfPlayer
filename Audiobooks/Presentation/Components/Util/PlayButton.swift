//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

struct PlayButton: View {
    let item: Item
    
    var body: some View {
        let progress = OfflineManager.shared.getProgress(item: item)
        let label = item as? Audiobook != nil ? "Listen" : "Play"
        
        Button {
            
        } label: {
            if let progress = progress, progress.progress > 0 && progress.progress < 1 {
                Label("\(label) • \((progress.duration - progress.currentTime).timeLeft())", systemImage: "play.fill")
            } else {
                Label("\(label)", systemImage: "play.fill")
            }
        }
        .buttonStyle(PlayNowButtonStyle(percentage: progress?.progress ?? 0))
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
