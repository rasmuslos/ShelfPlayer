//
//  AuthorList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation

internal struct AuthorList: View {
    let authors: [Author]
    
    var body: some View {
        ForEach(authors) { author in
            NavigationLink(destination: AuthorView(author)) {
                HStack(spacing: 12) {
                    ItemImage(cover: author.cover, cornerRadius: .infinity)
                        .frame(width: 60)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.name)
                        
                        Text("books \(author.bookCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowInsets(.init(top: 4, leading: 20, bottom: 4, trailing: 20))
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
