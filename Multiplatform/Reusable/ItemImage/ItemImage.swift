//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import NukeUI
import SPBase

struct ItemImage: View {
    let image: Item.Image?
    var cornerRadius: CGFloat = 7
    var aspectRatio = AspectRatioPolicy.square
    
    private var placeholder: some View {
        ZStack {
            Image(systemName: "book")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100)
                .foregroundStyle(.gray.opacity(0.5))
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.1))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    var body: some View {
        if let image = image {
            if aspectRatio == .none {
                LazyImage(url: image.url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    } else {
                        placeholder
                    }
                }
            } else {
                Color.clear
                    .overlay {
                        LazyImage(url: image.url) { phase in
                            if let image = phase.image {
                                if aspectRatio == .square {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                } else if aspectRatio == .squareFit {
                                    ZStack {
                                        image
                                            .resizable()
                                            .blur(radius: 25)
                                        
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    }
                                }
                            } else {
                                placeholder
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .padding(0)
            }
        } else {
            placeholder
        }
    }
    
    enum AspectRatioPolicy {
        case square
        case squareFit
        case none
    }
}

#Preview {
    ItemImage(image: Audiobook.fixture.image)
}
#Preview {
    ItemImage(image: nil)
}

#Preview {
    ItemImage(image: .init(url: .init(string: "https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.bookerworm.com%2Fimages%2F1984.jpg&f=1&nofb=1&ipt=064d244a11179919556d396a90b76dd33d095fc794135c0e7d889a5792fc0abc&ipo=images")!, type: .remote), aspectRatio: .squareFit)
}
#Preview {
    ItemImage(image: .init(url: .init(string: "https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2Fwww.bookerworm.com%2Fimages%2F1984.jpg&f=1&nofb=1&ipt=064d244a11179919556d396a90b76dd33d095fc794135c0e7d889a5792fc0abc&ipo=images")!, type: .remote), aspectRatio: .none)
}
