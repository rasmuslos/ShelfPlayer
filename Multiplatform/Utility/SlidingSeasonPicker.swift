//
//  SlidingPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.02.25.
//

import SwiftUI

struct SlidingSeasonPicker: View {
    @Binding var selection: String
    let values: [String]
    let makeLabel: (_: String) -> String
    
    @State private var scrollPosition = ScrollPosition()
    
    @ScaledMetric private var fontSize: CGFloat = 14
    @ScaledMetric private var capsuleHeight: CGFloat = 32
    
    private var font: UIFont {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)

        if let descriptor = font.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: fontSize)
        } else {
            return font
        }
    }
    private var textWidth: [Int: CGFloat] {
        Dictionary(uniqueKeysWithValues: values.enumerated().map {
            ($0.offset, NSString(string: makeLabel($0.element)).size(withAttributes: [.font: font]).width)
        })
    }
    
    private var selectionIndex: Int {
        values.firstIndex(of: selection) ?? 0
    }
    
    private var capsuleWidth: CGFloat {
        // width of the selected value + 8 units padding on each side
        (textWidth[selectionIndex] ?? 0) + 16
    }
    private var xOffset: CGFloat {
        // width of all previous values + the padding in between
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
                .font(Font(font))
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
