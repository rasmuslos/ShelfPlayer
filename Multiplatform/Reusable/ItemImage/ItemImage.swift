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
    @Environment(\.library) private var library
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    let cover: Cover?
    
    var cornerRadius: CGFloat = 8
    var aspectRatio = AspectRatioPolicy.square
    var priority: ImageRequest.Priority = .normal
    var contrastConfiguration: ContrastConfiguration? = .init()
    
    private var fallbackIcon: String {
        switch library.type {
        case .audiobooks:
            "book"
        case .podcasts:
            "play.square.stack.fill"
        default:
            "bookmark"
        }
    }
    private var placeholder: some View {
        ZStack {
            Image(systemName: fallbackIcon)
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
        Group {
            if aspectRatioPolicy == .none {
                LazyImage(request: request) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            .modifier(ContrastModifier(cornerRadius: cornerRadius, configuration: contrastConfiguration))
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
                    .modifier(ContrastModifier(cornerRadius: cornerRadius, configuration: contrastConfiguration))
                    .padding(0)
            }
        }
        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    enum AspectRatioPolicy {
        case square
        case squareFit
        case none
    }
    
    struct ContrastConfiguration {
        var shadowRadius: CGFloat = 4
        var shadowOpacity: CGFloat = 0.3
        
        var borderOpacity: CGFloat = 0.4
        var borderThickness: CGFloat = 1
        
        init() {}
        
        init(shadowRadius: CGFloat? = nil, shadowOpacity: CGFloat? = nil) {
            if let shadowRadius {
                self.shadowRadius = shadowRadius
            }
            if let shadowOpacity {
                self.shadowOpacity = shadowOpacity
            }
        }
        
        init(borderOpacity: CGFloat? = nil, borderThickness: CGFloat? = nil) {
            if let borderOpacity {
                self.borderOpacity = borderOpacity
            }
            if let borderThickness {
                self.borderThickness = borderThickness
            }
        }
    }
}

private struct ContrastModifier: ViewModifier {
    @Environment(\.library) private var library
    
    let cornerRadius: CGFloat
    let configuration: ItemImage.ContrastConfiguration?
    
    func body(content: Content) -> some View {
        if let configuration {
            switch library.type {
            case .audiobooks:
                content
                    .secondaryShadow(radius: configuration.shadowRadius, opacity: configuration.shadowOpacity)
            case .podcasts:
                content
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.gray.opacity(configuration.borderOpacity), lineWidth: configuration.borderThickness)
                    }
            default:
                content
            }
        } else {
            content
        }
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
