//
//  ItemImage.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import RFNotifications

public struct ItemImage: View {
    @Default(.forceAspectRatio) private var forceAspectRatio
    
    let itemID: ItemIdentifier?
    let size: ImageSize
    
    let cornerRadius: CGFloat
    let aspectRatio: AspectRatioPolicy
    let contrastConfiguration: ContrastConfiguration?
    
    public init(itemID: ItemIdentifier?, size: ImageSize, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, contrastConfiguration: ContrastConfiguration? = .init()) {
        self.itemID = itemID
        self.size = size
        
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.contrastConfiguration = contrastConfiguration
    }
    public init(item: Item?, size: ImageSize, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, contrastConfiguration: ContrastConfiguration? = .init()) {
        self.itemID = item?.id
        self.size = size
        
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.contrastConfiguration = contrastConfiguration
    }
    
    private var aspectRatioPolicy: AspectRatioPolicy {
        if forceAspectRatio && aspectRatio == .none {
            return .squareFit
        }
        
        return aspectRatio
    }
    
    @State private var image: Image? = nil
    
    public var body: some View {
        ZStack {
            if let image {
                if aspectRatioPolicy == .none {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: cornerRadius))
                        .modifier(ContrastModifier(itemID: itemID, cornerRadius: cornerRadius, configuration: contrastConfiguration))
                } else {
                    Color.clear
                        .overlay {
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
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: cornerRadius))
                        .modifier(ContrastModifier(itemID: itemID, cornerRadius: cornerRadius, configuration: contrastConfiguration))
                        .padding(0)
                }
            } else {
                ImagePlaceholder(itemID: itemID, cornerRadius: cornerRadius)
                    .task {
                        reload()
                    }
            }
        }
        .universalContentShape(.rect(cornerRadius: cornerRadius))
        .onReceive(RFNotification[.reloadImagesSwiftUI].publisher()) { itemID in
            if let itemID, self.itemID != itemID {
                return
            }
            
            reload()
        }
    }
    
    private nonisolated func reload() {
        Task {
            guard let data = await ItemImageCache.shared[itemID, size], let uiImage = UIImage(data: data) else {
                return
            }
            
            let image = Image(uiImage: uiImage)
            
            await MainActor.run {
                withAnimation {
                    self.image = image
                }
            }
        }
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

private actor ItemImageCache: Sendable {
    var active = [ItemImageCache.Key: Task<Data?, Never>]()
    var cached = NSCache<ItemImageCache.Key, NSData>()
    
    private init() {
        RFNotification[.reloadImages].subscribe { [weak self] itemID in
            Task {
                await self?.flush()
                await RFNotification[.reloadImagesSwiftUI].send(payload: itemID)
            }
        }
    }
    
    private func flush() {
        cached.removeAllObjects()
    }
    private func store(_ data: Data, for key: Key) {
        cached.setObject(data as NSData, forKey: key)
    }
    
    subscript(itemID: ItemIdentifier?, size: ImageSize) -> Data? {
        get async {
            guard let itemID else {
                return nil
            }
            
            let key = Key(itemID: itemID, size: size)
            
            if let cached = cached.object(forKey: key) as? Data {
                return cached
            } else {
                active[key] = .init {
                    let data = await itemID.data(size: size)
                    
                    if let data {
                        store(data, for: key)
                    }
                    
                    return data
                }
                
                return await active[key]!.value
            }
        }
    }
    
    static let shared = ItemImageCache()
    
    final class Key: Equatable, Hashable {
        let itemID: ItemIdentifier
        let size: ImageSize
        
        init(itemID: ItemIdentifier, size: ImageSize) {
            self.itemID = itemID
            self.size = size
        }
        
        static func == (lhs: ItemImageCache.Key, rhs: ItemImageCache.Key) -> Bool {
            lhs.itemID == rhs.itemID && lhs.size == rhs.size
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(itemID)
            hasher.combine(size)
        }
    }
}

fileprivate extension RFNotification.IsolatedNotification {
    static var reloadImagesSwiftUI: IsolatedNotification<ItemIdentifier?> { .init("io.rfk.shelfPlayer.reloadImages.SwiftUI") }
}

#if DEBUG
#Preview {
    ItemImage(item: Audiobook.fixture, size: .large)
}
#Preview {
    ItemImage(item: Audiobook.fixture, size: .small)
        .frame(width: 40)
}
#endif

