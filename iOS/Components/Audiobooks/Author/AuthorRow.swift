//
//  AuthorRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBaseKit

struct AuthorRow: View {
    let author: Author
    
    var body: some View {
        HStack {
            ItemImage(image: author.image)
                .clipShape(RoundedRectangle(cornerRadius: 10000))
                .frame(width: 50)
            
            Text(author.name)
        }
    }
}

#Preview {
    List {
        AuthorRow(author: Author.fixture)
        AuthorRow(author: Author.fixture)
        AuthorRow(author: Author.fixture)
        AuthorRow(author: Author.fixture)
        AuthorRow(author: Author.fixture)
        AuthorRow(author: Author.fixture)
    }
    .listStyle(.plain)
}
