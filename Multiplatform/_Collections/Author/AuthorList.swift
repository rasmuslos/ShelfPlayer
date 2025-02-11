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
    let onAppear: ((_ author: Author) -> Void)
    
    var body: some View {
        ForEach(authors) { author in
            NavigationLink(destination: AuthorView(author)) {
                HStack(spacing: 12) {
                    ItemImage(item: author, cornerRadius: .infinity)
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
            .onAppear {
                onAppear(author)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            AuthorList(authors: .init(repeating: .fixture, count: 7)) { _ in }
        }
        .listStyle(.plain)
    }
}
#endif
