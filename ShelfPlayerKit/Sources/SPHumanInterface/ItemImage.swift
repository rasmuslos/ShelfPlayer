//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import Nuke
import NukeUI
import Defaults
import RFNotifications
import SPFoundation
import SPPersistence

public struct RequestImage: View {
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    var request: ImageRequest?
    
    let cornerRadius: CGFloat
    let aspectRatio: AspectRatioPolicy
    let priority: ImageRequest.Priority
    let contrastConfiguration: ContrastConfiguration?
    
    let associatedItemID: ItemIdentifier?
    
    @State private var id = UUID()
    
    public init(request: ImageRequest?, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, priority: ImageRequest.Priority = .normal, contrastConfiguration: ContrastConfiguration? = .init(), associatedItemID: ItemIdentifier? = nil) {
        self.request = request
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.priority = priority
        self.contrastConfiguration = contrastConfiguration
        self.associatedItemID = associatedItemID
    }
    
    private var aspectRatioPolicy: AspectRatioPolicy {
        if forceAspectRatio && aspectRatio == .none {
            return .squareFit
        }
        
        return aspectRatio
    }
    
    public var body: some View {
        Group {
            if aspectRatioPolicy == .none {
                LazyImage(request: request) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: cornerRadius))
                            .modifier(ContrastModifier(itemID: associatedItemID, cornerRadius: cornerRadius, configuration: contrastConfiguration))
                    } else {
                        Placeholder(itemID: associatedItemID, cornerRadius: cornerRadius)
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
                                Placeholder(itemID: associatedItemID, cornerRadius: cornerRadius)
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .modifier(ContrastModifier(itemID: associatedItemID, cornerRadius: cornerRadius, configuration: contrastConfiguration))
                    .padding(0)
            }
        }
        .id(id)
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: cornerRadius))
        .onReceive(RFNotification[.reloadImages].publisher()) { itemID in
            if let itemID, self.associatedItemID != itemID {
                return
            }
            
            reload()
        }
    }
    
    private func reload() {
        id = UUID()
    }
    
    public enum AspectRatioPolicy {
        case square
        case squareFit
        case none
    }
    
    public struct ContrastConfiguration {
        var shadowRadius: CGFloat = 4
        var shadowOpacity: CGFloat = 0.3
        
        var borderOpacity: CGFloat = 0.4
        var borderThickness: CGFloat = 1
        
        public init() {}
        
        public init(shadowRadius: CGFloat? = nil, shadowOpacity: CGFloat? = nil) {
            if let shadowRadius {
                self.shadowRadius = shadowRadius
            }
            if let shadowOpacity {
                self.shadowOpacity = shadowOpacity
            }
        }
        
        public init(borderOpacity: CGFloat? = nil, borderThickness: CGFloat? = nil) {
            if let borderOpacity {
                self.borderOpacity = borderOpacity
            }
            if let borderThickness {
                self.borderThickness = borderThickness
            }
        }
    }
}

public struct ItemImage: View {
    let itemID: ItemIdentifier?
    let size: ItemIdentifier.CoverSize
    
    let cornerRadius: CGFloat
    let aspectRatio: RequestImage.AspectRatioPolicy
    let priority: ImageRequest.Priority
    let contrastConfiguration: RequestImage.ContrastConfiguration?
    
    public init(itemID: ItemIdentifier?,
         size: ItemIdentifier.CoverSize,
         cornerRadius: CGFloat = 8,
         aspectRatio: RequestImage.AspectRatioPolicy = .square,
         priority: ImageRequest.Priority = .normal,
         contrastConfiguration: RequestImage.ContrastConfiguration? = .init()) {
        self.itemID = itemID
        self.size = size
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.priority = priority
        self.contrastConfiguration = contrastConfiguration
    }
    public init(item: Item?,
         size: ItemIdentifier.CoverSize,
         cornerRadius: CGFloat = 8,
         aspectRatio: RequestImage.AspectRatioPolicy = .square,
         priority: ImageRequest.Priority = .normal,
         contrastConfiguration: RequestImage.ContrastConfiguration? = .init()) {
        self.init(itemID: item?.id, size: size, cornerRadius: cornerRadius, aspectRatio: aspectRatio, priority: priority)
    }
    
    @State private var request: ImageRequest?
    
    public var body: some View {
        if let request {
            RequestImage(request: request, cornerRadius: cornerRadius, aspectRatio: aspectRatio, priority: priority, contrastConfiguration: contrastConfiguration, associatedItemID: itemID)
        } else {
            Placeholder(itemID: itemID, cornerRadius: cornerRadius)
                .task {
                    request = await itemID?.coverRequest(size: size)
                }
        }
    }
}

private struct Placeholder: View {
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    
    private var itemIDIcon: String? {
        guard let itemID else {
            return nil
        }
        
        return itemID.type.icon
    }
    private var fallbackIcon: String {
        if let itemID {
            itemID.type.icon
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
        GeometryReader { geometryProxy in
            ZStack {
                Image(systemName: fallbackIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometryProxy.size.width / 3)
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
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
    
    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    let configuration: RequestImage.ContrastConfiguration?
    
    private var libraryType: Library.MediaType? {
        if let library {
            return library.type
        } else if let itemID {
            switch itemID.type {
            case .audiobook, .narrator, .author, .series:
                return .audiobooks
            case .podcast, .episode:
                return .podcasts
            }
        }
        
        return nil
    }
    
    func body(content: Content) -> some View {
        if let configuration {
            switch libraryType {
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

public extension ItemIdentifier.ItemType {
    var icon: String {
        switch self {
            case .audiobook:
                "book"
            case .author:
                "person"
            case .narrator:
                "microphone.fill"
            case .series:
                "rectangle.grid.2x2"
            case .podcast:
                "square.stack"
            case .episode:
                "play.square"
        }
    }
}

#if DEBUG
#Preview {
    RequestImage(request: .init(url: .init(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmacjeux.fr%2Fwp-content%2Fuploads%2F2021%2F02%2Fsynd1.jpg&f=1&nofb=1&ipt=a414ab5944af23112c3d36713648379879e8fce234a20df58727c714645a11c5&ipo=images")!), cornerRadius: 0, aspectRatio: .none, contrastConfiguration: nil)
}

#Preview {
    ItemImage(item: Audiobook.fixture, size: .large)
}
#Preview {
    ItemImage(item: Audiobook.fixture, size: .small)
        .frame(width: 40)
}
#endif
