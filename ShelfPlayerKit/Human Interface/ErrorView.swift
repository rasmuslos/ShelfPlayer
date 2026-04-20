//
//  ErrorView.swift
//  ShelfFoundation
//

import SwiftUI

public struct ErrorView: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey?

    public init(
        _ title: LocalizedStringKey = "error.unavailable",
        systemImage: String = "exclamationmark.triangle",
        description: LocalizedStringKey? = "error.unavailable.text"
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }

    public var body: some View {
        ScrollView {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal, .vertical])

                if let description {
                    ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
                } else {
                    ContentUnavailableView(title, systemImage: systemImage)
                }
            }
        }
    }
}

#Preview {
    ErrorView()
}
