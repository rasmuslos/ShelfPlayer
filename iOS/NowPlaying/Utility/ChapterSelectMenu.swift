//
//  ChapterSelectMenu.swift
//  iOS
//
//  Created by Rasmus Krämer on 04.02.24.
//

import SwiftUI
import SPBase
import SPPlayback

struct ChapterSelectMenu: View {
    var body: some View {
        ForEach(AudioPlayer.shared.chapters) { chapter in
            Button {
                AudioPlayer.shared.seek(to: chapter.start)
            } label: {
                if chapter == AudioPlayer.shared.chapter {
                    Label(chapter.title, systemImage: "checkmark")
                } else {
                    Text(chapter.title)
                }
            }
        }
    }
}

#Preview {
    ChapterSelectMenu()
}
