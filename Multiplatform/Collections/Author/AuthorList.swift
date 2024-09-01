//
//  AuthorList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation

struct AuthorList: View {
    let authors: [Author]
    
    var body: some View {
        ForEach(authors) { author in
            NavigationLink(destination: AuthorView(author)) {
                AuthorRow(author: author)
            }
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    }
}

extension AuthorList {
    struct AuthorRow: View {
        let author: Author
        
        var body: some View {
            HStack {
                ItemImage(cover: author.cover)
                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                    .frame(width: 50)
                
                Text(author.name)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            AuthorList(authors: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
}
#endif
