//
//  AudiobookRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct AudiobooksRow: View {
    let audiobooks: [Audiobook]
    var amount = 3
    
    var body: some View {
        // size = (width - (padding leading (20) + padding trailing (20) + gap (10) * (amount - 1))) / amount
        let size = (UIScreen.main.bounds.width - (40 + 10 * CGFloat(amount - 1))) / CGFloat(amount)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(audiobooks) { audiobook in
                    NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                        AudiobookCover(audiobook: audiobook)
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
    var amount = 3
    var navigatable = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if navigatable {
                NavigationLink(destination: GridView(title: title, audiobooks: audiobooks)) {
                    HStack(alignment: .lastTextBaseline) {
                        AudiobooksRowTitle(title: title)
                        Image(systemName: "chevron.right.circle.fill")
                            .imageScale(.small)
                            .padding(.leading, -15)
                    }
                }
                .buttonStyle(.plain)
            } else {
                AudiobooksRowTitle(title: title)
            }
            
            AudiobooksRow(audiobooks: audiobooks, amount: amount)
        }
    }
    
    struct GridView: View {
        let title: String
        let audiobooks: [Audiobook]
        
        var body: some View {
            ScrollView {
                AudiobookGrid(audiobooks: audiobooks)
                    .padding(.horizontal)
            }
            .navigationTitle(title)
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

#Preview {
    NavigationStack {
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
        ], navigatable: true)
    }
}
