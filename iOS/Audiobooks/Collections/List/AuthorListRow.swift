//
//  AuthorListRow.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import SPBase

struct AuthorListRow: View {
    let author: Author
    
    var body: some View {
        HStack {
            ItemImage(image: author.image)
                .frame(width: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10000))
            
            Text(author.name)
        }
    }
}

#Preview {
    List {
        AuthorListRow(author: Author.fixture)
    }
}
