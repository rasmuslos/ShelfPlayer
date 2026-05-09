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

    @Namespace private var namespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(values, id: \.self) { value in
                        Button {
                            withAnimation(.smooth) { selection = value }
                        } label: {
                            Text(makeLabel(value))
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background {
                            if value == selection {
                                Capsule()
                                    .fill(.clear)
                                    .glassEffect(.regular.tint(.accentColor), in: .capsule)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .id(value)
                    }
                }
                .padding(4)
            }
            .glassEffect(.regular, in: .capsule)
            .onChange(of: selection) { _, new in
                withAnimation(.smooth) { proxy.scrollTo(new) }
            }
            .onAppear {
                proxy.scrollTo(selection)
            }
        }
        .padding(.horizontal, 12)
    }
}
