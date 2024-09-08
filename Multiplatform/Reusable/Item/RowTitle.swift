//
//  RowTitle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import SPFoundation

internal struct RowTitle: View {
    @Default(.useSerifFont) private var useSerifFont
    
    let title: String
    var fontDesign: Font.Design? = nil
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontDesign(fontDesign == .serif && !useSerifFont ? nil : fontDesign)
    }
}

internal struct AudiobookRow: View {
    let title: String
    let audiobooks: [Audiobook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if audiobooks.count > 5 {
                    NavigationLink {
                        ScrollView {
                            AudiobookVGrid(audiobooks: audiobooks)
                                .padding(.horizontal, 20)
                        }
                        .navigationTitle(title)
                        .modifier(NowPlaying.SafeAreaModifier())
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            RowTitle(title: title, fontDesign: .serif)
                            
                            Image(systemName: "chevron.right.circle.fill")
                                .imageScale(.small)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    RowTitle(title: title, fontDesign: .serif)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
            
            AudiobookHGrid(audiobooks: audiobooks, small: true)
        }
    }
}

#Preview {
    RowTitle(title: "Title")
}

#Preview {
    RowTitle(title: "Title", fontDesign: .serif)
}

#Preview {
    AudiobookRow(title: "Title", audiobooks: .init(repeating: [.fixture], count: 7))
}
