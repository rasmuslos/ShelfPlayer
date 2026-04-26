//
//  ItemImage.swift
//  ShelfPlayerKit
//

import SwiftUI

public struct ItemImage: View {
    let itemID: ItemIdentifier?
    let size: ImageSize

    let cornerRadius: CGFloat
    let aspectRatio: AspectRatioPolicy
    let contrastConfiguration: ContrastConfiguration?
    let fallbackLabel: String?

    private var aspectRatioPolicy: AspectRatioPolicy {
        if let itemID, itemID.type == .author || itemID.type == .narrator {
            return .square
        }

        if AppSettings.shared.forceAspectRatio && aspectRatio == .none {
            return .squareFit
        }

        return aspectRatio
    }

    @State private var image: Image?

    #if DEBUG
    @AppStorage("io.rfk.shelfPlayer.debug.forceImagePlaceholder") private var forcePlaceholder = false
    #endif

    private var displayedImage: Image? {
        #if DEBUG
        if forcePlaceholder { return nil }
        #endif
        return image
    }

    public init(itemID: ItemIdentifier?, size: ImageSize, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, contrastConfiguration: ContrastConfiguration? = .init(), fallbackLabel: String? = nil) {
        self.itemID = itemID
        self.size = size

        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.contrastConfiguration = contrastConfiguration
        self.fallbackLabel = fallbackLabel

        if let itemID, let cached = itemID.cachedPlatformImage(size: size) {
            _image = State(initialValue: Image(uiImage: cached))
        }
    }

    public init(item: Item?, size: ImageSize, cornerRadius: CGFloat = 8, aspectRatio: AspectRatioPolicy = .square, contrastConfiguration: ContrastConfiguration? = .init(), showLabelFallback: Bool = false) {
        self.itemID = item?.id
        self.size = size

        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.contrastConfiguration = contrastConfiguration
        self.fallbackLabel = showLabelFallback ? item?.name : nil

        if let itemID = item?.id, let cached = itemID.cachedPlatformImage(size: size) {
            _image = State(initialValue: Image(uiImage: cached))
        }
    }

    public var body: some View {
        ZStack {
            if let image = displayedImage {
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
                ImagePlaceholder(itemID: itemID, cornerRadius: cornerRadius, fallbackLabel: fallbackLabel)
                    .onAppear {
                        reload()
                    }
            }
        }
        .universalContentShape(.rect(cornerRadius: cornerRadius))
        .onReceive(AppEventSource.shared.reloadImages) { itemID in
            if let itemID, self.itemID != itemID {
                return
            }

            reload()
        }
    }

    private func reload() {
        Task {
            guard let image = await itemID?.platformImage(size: size) else {
                return
            }

            await MainActor.run {
                withAnimation {
                    self.image = Image(uiImage: image)
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

#if DEBUG
#Preview {
    ItemImage(item: Audiobook.fixture, size: .large)
}

#Preview {
    ItemImage(item: Audiobook.fixture, size: .small)
        .frame(width: 40)
}
#endif
