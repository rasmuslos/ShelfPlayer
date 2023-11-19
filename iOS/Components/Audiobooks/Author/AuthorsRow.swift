//
//  AuthorsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import AudiobooksKit

struct AuthorsRow: View {
    let authors: [Author]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - (90)) / 4
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(authors) { author in
                    NavigationLink(destination: AuthorView(author: author)) {
                        AuthorAvatar(author: author)
                            .frame(width: size)
                            .padding(.leading, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, 10)
            .padding(.trailing, 20)
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

struct AuthorTitleRow: View {
    let title: String
    let authors: [Author]
    
    var body: some View {
        VStack(alignment: .leading) {
            RowTitle(title: title, fontDesign: .serif)
            AuthorsRow(authors: authors)
        }
    }
}

#Preview {
    NavigationStack {
        AuthorsRow(authors: [
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
        ])
    }
}
