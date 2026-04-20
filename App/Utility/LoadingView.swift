//
//  LoadingView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    var step: LocalizedStringKey?

    var body: some View {
        Inner(step: step)
    }

    struct Inner: View {
        var step: LocalizedStringKey?

        var body: some View {
            VStack(spacing: 0) {
                ProgressView()
                    .tint(.secondary)
                    .scaleEffect(2)
                    .frame(width: 40, height: 40)
                    .padding(.bottom, 8)

                Text("loading")
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)

                if let step {
                    Text(step)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LoadingView()
}
