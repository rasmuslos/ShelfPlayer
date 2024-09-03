//
//  ChapterSelectMenu.swift
//  iOS
//
//  Created by Rasmus Krämer on 04.02.24.
//

import SwiftUI
import SPFoundation
import SPPlayback

internal extension NowPlaying {
    struct ChapterMenu: View {
        @Environment(ViewModel.self) private var viewModel
        
        var body: some View {
            ForEach(viewModel.chapters) { chapter in
                Toggle(chapter.title, isOn: .init(get: {
                    chapter == viewModel.chapter
                }, set: { _ in
                    AudioPlayer.shared.itemCurrentTime = chapter.start
                }))
            }
        }
    }
}
