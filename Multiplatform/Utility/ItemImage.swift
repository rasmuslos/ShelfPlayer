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

struct RequestImage: View {
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    var request: ImageRequest?
    
    let cornerRadius: CGFloat
    let aspectRatio: AspectRatioPolicy
    let priority: ImageRequest.Priority
    let contrastConfiguration: ContrastConfiguration?
    
    init(request: ImageRequest?, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, priority: ImageRequest.Priority = .normal, contrastConfiguration: ContrastConfiguration? = .init()) {
        self.request = request
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.priority = priority
        self.contrastConfiguration = contrastConfiguration
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
                        Placeholder(itemID: nil, cornerRadius: cornerRadius)
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
                                Placeholder(itemID: nil, cornerRadius: cornerRadius)
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

struct ItemImage: View {
    let itemID: ItemIdentifier?
    
    var cornerRadius: CGFloat
    var aspectRatio: RequestImage.AspectRatioPolicy
    var priority: ImageRequest.Priority
    var contrastConfiguration: RequestImage.ContrastConfiguration?
    
    init(itemID: ItemIdentifier?,
         cornerRadius: CGFloat = 8,
         aspectRatio: RequestImage.AspectRatioPolicy = .square,
         priority: ImageRequest.Priority = .normal,
         contrastConfiguration: RequestImage.ContrastConfiguration? = .init()) {
        self.itemID = itemID
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.priority = priority
        self.contrastConfiguration = contrastConfiguration
    }
    init(item: Item?,
         cornerRadius: CGFloat = 8,
         aspectRatio: RequestImage.AspectRatioPolicy = .square,
         priority: ImageRequest.Priority = .normal,
         contrastConfiguration: RequestImage.ContrastConfiguration? = .init()) {
        self.init(itemID: item?.id, cornerRadius: cornerRadius, aspectRatio: aspectRatio, priority: priority)
    }
    
    @State private var request: ImageRequest?
    
    var body: some View {
        if let request {
            RequestImage(request: request, cornerRadius: cornerRadius, aspectRatio: aspectRatio, priority: priority, contrastConfiguration: contrastConfiguration)
        } else {
            Placeholder(itemID: itemID, cornerRadius: cornerRadius)
                .task {
                    request = await itemID?.coverRequest
                }
        }
    }
}

private struct Placeholder: View {
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    
    private var fallbackIcon: String {
        if let itemID, itemID.type == .author {
            "person"
        } else {
            switch library?.type {
            case .audiobooks:
                "book"
            case .podcasts:
                "play.square.stack.fill"
            default:
                "bookmark"
            }
        }
    }
    
    var body: some View {
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
}

private struct ContrastModifier: ViewModifier {
    @Environment(\.library) private var library
    
    let cornerRadius: CGFloat
    let configuration: RequestImage.ContrastConfiguration?
    
    func body(content: Content) -> some View {
        if let configuration {
            switch library?.type {
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
    RequestImage(request: .init(url: .init(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmacjeux.fr%2Fwp-content%2Fuploads%2F2021%2F02%2Fsynd1.jpg&f=1&nofb=1&ipt=a414ab5944af23112c3d36713648379879e8fce234a20df58727c714645a11c5&ipo=images")!), cornerRadius: 0, aspectRatio: .none, contrastConfiguration: nil)
}

#Preview {
    ItemImage(item: Audiobook.fixture)
}
#endif
