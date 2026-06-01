//
//  HeroBackButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct HeroBackButton: View {
    @Environment(\.navigationContext) private var navigationContext
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss

    @ViewBuilder
    private var label: some View {
        Label("navigation.back", systemImage: "chevron.left")
            .labelStyle(.iconOnly)
    }

    var body: some View {
        if isPresented {
            if let navigationContext {
                Menu {
                    ForEach(navigationContext.path.prefix(max(0, navigationContext.path.count - 1)).enumerated().reversed(), id: \.offset) { index, destination in
                        Button(destination.label) {
                            navigationContext.path.remove(atOffsets: .init((index + 1)..<navigationContext.path.count))
                        }
                    }

                    Button(navigationContext.tab.label) {
                        navigationContext.path.removeAll()
                    }
                } label: {
                    label
                } primaryAction: {
                    dismiss()
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    label
                }
            }
        }
    }
}
