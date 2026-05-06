//
//  DescriptionSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.03.25.
//

import SwiftUI
import ShelfPlayback

struct DescriptionSheet: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let item: Item

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(spacing: 0) {
                    if let description = item.description {
                        Text(description)
                    } else {
                        Text("item.description.missing")
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(horizontalSizeClass == .compact ? .visible : .hidden)
    }
}

#if DEBUG
#Preview {
    DescriptionSheet(item: Audiobook.fixture)
}

#Preview {
    DescriptionSheet(item: Person.authorFixture)
}
#endif
