//
//  AuthorView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import ShelfPlayerKit

extension AuthorView {
    struct Header: View {
        let author: Author
        
        var body: some View {
            VStack {
                ItemImage(image: author.image)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                
                Text(author.name)
                    .fontDesign(.serif)
                    .font(.headline)
            }
        }
    }
}
