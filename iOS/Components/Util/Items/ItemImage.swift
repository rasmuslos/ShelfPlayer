//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import NukeUI
import ShelfPlayerKit

struct ItemImage: View {
    let image: Item.Image?
    
    @State var progress: Double?
    
    var placeholder: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "book")
                Spacer()
            }
            Spacer()
        }
        .background(.tertiary)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
    
    var body: some View {
        if let image = image {
            LazyImage(url: image.url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    placeholder
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .padding(0)
        } else {
            placeholder
        }
    }
}

#Preview {
    ItemImage(image: Audiobook.fixture.image)
}
#Preview {
    ItemImage(image: nil)
}
