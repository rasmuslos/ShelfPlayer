//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import NukeUI
import Defaults
import ShelfPlayerKit

internal struct ItemImage: View {
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    let cover: Cover?
    
    var cornerRadius: CGFloat = 8
    var aspectRatio = AspectRatioPolicy.square
    var priority: ImageRequest.Priority = .normal
    
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
    
    private var request: ImageRequest? {
        guard let url = cover?.url else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        
        for header in AudiobookshelfClient.shared.customHTTPHeaders {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        return .init(urlRequest: urlRequest, priority: priority)
    }
    
    private var aspectRatioPolicy: AspectRatioPolicy {
        if forceAspectRatio && aspectRatio == .none {
            return .squareFit
        }
        
        return aspectRatio
    }
    
    var body: some View {
        if aspectRatioPolicy == .none {
            LazyImage(request: request) { phase in
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
                    LazyImage(request: request) { phase in
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
    }
    
    enum AspectRatioPolicy {
        case square
        case squareFit
        case none
    }
}

#if DEBUG
#Preview {
    ItemImage(cover: Audiobook.fixture.cover)
}
#Preview {
    ItemImage(cover: nil)
}
#endif
