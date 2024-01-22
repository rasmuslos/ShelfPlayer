//
//  AudiobookCover.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import SwiftUI
import SPBase

struct AudiobookCover: View {
    let audiobook: Audiobook
    
    var body: some View {
        ItemStatusImage(item: audiobook)
            .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
    }
}

#Preview {
    AudiobookCover(audiobook: Audiobook.fixture)
}
