//
//  SubpageLink.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.04.26.
//

import SwiftUI

struct SubpageLink<Destination: View>: View {
    let title: LocalizedStringKey
    let destination: () -> Destination

    init(_ title: LocalizedStringKey, @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.destination = destination
    }

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 0) {
                Text(title)
                    .font(.headline)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
