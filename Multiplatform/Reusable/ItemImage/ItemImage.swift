//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import NukeUI
import Defaults
import SPFoundation

struct ItemImage: View {
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    let image: Cover?
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
        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var aspectRatioPolicy: AspectRatioPolicy {
        if forceAspectRatio && aspectRatio == .none {
            return .squareFit
        }
        
        return aspectRatio
    }
    
    var body: some View {
        if let image = image {
            if aspectRatioPolicy == .none {
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
                                if aspectRatioPolicy == .square {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                } else if aspectRatioPolicy == .squareFit {
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
    ItemImage(image: Audiobook.fixture.cover)
}
#Preview {
    ItemImage(image: nil)
}
