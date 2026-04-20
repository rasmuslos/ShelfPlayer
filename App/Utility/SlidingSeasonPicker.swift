//
//  SlidingSeasonPicker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.02.25.
//

import SwiftUI

struct SlidingSeasonPicker: View {
    @Binding var selection: String
    let values: [String]
    let makeLabel: (_: String) -> String

    @State private var scrollPosition = ScrollPosition()

    @ScaledMetric private var capsuleHeight: CGFloat = 32

    private var measurementFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)

        if let descriptor = font.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: font.pointSize)
        } else {
            return font
        }
    }
    private var textWidth: [Int: CGFloat] {
        Dictionary(uniqueKeysWithValues: values.enumerated().map {
            ($0.offset, NSString(string: makeLabel($0.element)).size(withAttributes: [.font: measurementFont]).width)
        })
    }

    private var selectionIndex: Int {
        values.firstIndex(of: selection) ?? 0
    }

    private var capsuleWidth: CGFloat {
        (textWidth[selectionIndex] ?? 0) + 16
    }
    private var xOffset: CGFloat {
        (0..<selectionIndex).reduce(0) { $0 + (textWidth[$1] ?? 0) } + CGFloat(selectionIndex) * 16
    }

    @ViewBuilder
    private var valueButtons: some View {
        LazyHStack(spacing: 16) {
            ForEach(Array(values.enumerated()), id: \.offset) { (index, value) in
                Button(makeLabel(value)) {
                    selection = value
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .fontDesign(.rounded)
                .frame(width: textWidth[index])
            }
        }
        .padding(8)
    }
    @ViewBuilder
    private var capsule: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .offset(x: xOffset)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .leading) {
                capsule

                valueButtons

                valueButtons
                    .foregroundStyle(.white)
                    .mask(alignment: .leading) {
                        capsule
                    }
            }
            .padding(.horizontal, 12)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.75), value: selection)
        }
        .frame(height: capsuleHeight)
        .scrollPosition($scrollPosition)
        .onAppear {
            scrollPosition.scrollTo(x: xOffset - 12)
        }
    }
}
