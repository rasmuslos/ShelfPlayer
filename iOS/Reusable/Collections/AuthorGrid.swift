//
//  AuthorsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBase

struct AuthorGrid: View {
    let authors: [Author]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - (90)) / 4
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(authors) { author in
                    NavigationLink(destination: AuthorView(author: author)) {
                        AuthorGridItem(author: author)
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

extension AuthorGrid {
    struct AuthorGridItem: View {
        let author: Author
        
        var body: some View {
            VStack {
                ItemImage(image: author.image)
                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                
                Text(author.name)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuthorGrid(authors: [
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
        ])
    }
}
