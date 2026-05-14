//
//  InformationList.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 27.12.25.
//

import SwiftUI

struct InformationListRow: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent(title, value: value)
            .font(.footnote)
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }

    @ViewBuilder
    static func label<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        LabeledContent(title, content: content)
            .font(.footnote)
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

struct InformationListTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.headline)

            Spacer(minLength: 0)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 12, leading: 20, bottom: 0, trailing: 20))
    }
}
