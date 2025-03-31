//
//  AuthorList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayerKit

struct AuthorList: View {
    let authors: [Author]
    let onAppear: ((_: Author) -> Void)
    
    var body: some View {
        ForEach(authors) { author in
            NavigationLink(destination: AuthorView(author)) {
                HStack(spacing: 8) {
                    ItemImage(item: author, size: .tiny, cornerRadius: .infinity)
                        .frame(width: 52)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.name)
                        
                        Text("item.count.audiobooks \(author.bookCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
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
    .previewEnvironment()
}
#endif
