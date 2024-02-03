//
//  AuthorList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPBase

struct AuthorList: View {
    let authors: [Author]
    
    var body: some View {
        ForEach(authors) { author in
            NavigationLink(destination: AuthorView(author: author)) {
                AuthorRow(author: author)
            }
        }
    }
}

extension AuthorList {
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
}

#Preview {
    NavigationStack {
        List {
            AuthorList(authors: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
}
