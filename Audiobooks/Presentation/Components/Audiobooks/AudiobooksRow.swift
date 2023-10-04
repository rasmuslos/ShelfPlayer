//
//  AudiobookRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct AudiobooksRow: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        // size = (width - (padding leading + padding trailing + gap * 2 + 15)) / 3
        let size = (UIScreen.main.bounds.width - 60) / 3
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(audiobooks) { audiobook in
                    NavigationLink(destination: Text(":)")) {
                        AudiobookColumn(audiobook: audiobook)
                            .frame(width: size)
                            .padding(.leading, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 20)
        }
    }
}

struct AudiobooksRowTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontDesign(.serif)
            .padding(.horizontal)
            .padding(.bottom, 0)
            .padding(.top, 10)
    }
}

struct AudiobooksRowContainer: View {
    let title: String
    let audiobooks: [Audiobook]
    
    var body: some View {
        VStack(alignment: .leading) {
            AudiobooksRowTitle(title: title)
            AudiobooksRow(audiobooks: audiobooks)
        }
    }
}

#Preview {
    AudiobooksRowContainer(title: "Good books", audiobooks: [
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
        Audiobook.fixture,
    ])
}
