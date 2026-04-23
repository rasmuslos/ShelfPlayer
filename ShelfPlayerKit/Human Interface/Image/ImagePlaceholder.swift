//
//  ImagePlaceholder.swift
//  ShelfPlayerKit
//

import SwiftUI

struct ImagePlaceholder: View {
    @Environment(\.library) private var library

    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    var fallbackLabel: String? = nil

    private var fallbackIcon: String {
        if let itemID {
            itemID.type.icon
        } else {
            switch library?.id.type {
            case .audiobooks:
                "book"
            case .podcasts:
                "play.square.stack.fill"
            default:
                "bookmark"
            }
        }
    }

    private func initials(from text: String) -> String {
        let skipWords: Set<String> = ["the", "a", "an"]
        let words = text
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .filter { !skipWords.contains($0.lowercased()) }

        if words.count >= 2 {
            return words.prefix(3).compactMap(\.first).map(String.init).joined().uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return String(text.prefix(2)).uppercased()
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                if let fallbackLabel, !fallbackLabel.isEmpty {
                    let useInitials = geometryProxy.size.width < 120

                    Text(useInitials ? initials(from: fallbackLabel) : fallbackLabel)
                        .font(.system(size: useInitials ? geometryProxy.size.width * 0.34 : geometryProxy.size.width * 0.12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(useInitials ? 1 : 4)
                        .minimumScaleFactor(0.5)
                        .padding(useInitials ? 0 : geometryProxy.size.width * 0.08)
                } else {
                    Image(systemName: fallbackIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometryProxy.size.width / 3)
                        .foregroundStyle(.gray.opacity(0.5))
                }
            }
            .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.3))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .universalContentShape(.rect(cornerRadius: cornerRadius))
    }
}

#if DEBUG
#Preview("Icon fallback") {
    ImagePlaceholder(itemID: nil, cornerRadius: 8)
        .frame(width: 200, height: 200)
        .padding()
}

#Preview("Initials – tiny") {
    ImagePlaceholder(itemID: nil, cornerRadius: 8, fallbackLabel: "The Lord of the Rings")
        .frame(width: 44, height: 44)
        .padding()
}

#Preview("Initials – small") {
    ImagePlaceholder(itemID: nil, cornerRadius: 8, fallbackLabel: "Harry Potter")
        .frame(width: 80, height: 80)
        .padding()
}

#Preview("Title – regular") {
    ImagePlaceholder(itemID: nil, cornerRadius: 8, fallbackLabel: "The Lord of the Rings")
        .frame(width: 200, height: 200)
        .padding()
}

#Preview("Title – large") {
    ImagePlaceholder(itemID: nil, cornerRadius: 12, fallbackLabel: "A Brief History of Time")
        .frame(width: 320, height: 320)
        .padding()
}

#Preview("Single word") {
    ImagePlaceholder(itemID: nil, cornerRadius: 8, fallbackLabel: "1984")
        .frame(width: 80, height: 80)
        .padding()
}

#Preview("Circle") {
    ImagePlaceholder(itemID: nil, cornerRadius: .infinity, fallbackLabel: "Jane Doe")
        .frame(width: 80, height: 80)
        .padding()
}
#endif
