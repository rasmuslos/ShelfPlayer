//
//  AuthorAvatar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBase

struct AuthorAvatar: View {
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

#Preview {
    AuthorAvatar(author: Author.fixture)
}
