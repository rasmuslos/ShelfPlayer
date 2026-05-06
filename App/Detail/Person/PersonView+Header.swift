//
//  PersonView+Header.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import ShelfPlayback

extension PersonView {
    struct Header: View {
        @Environment(PersonViewModel.self) private var viewModel

        var body: some View {
            ViewThatFits {
                RegularPresentation()
                CompactPresentation()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: "")
                }
            }
        }
    }
}

private struct DescriptionButton: View {
    @Environment(PersonViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let alignment: TextAlignment
    let lineLimit: Int

    var body: some View {
        if let description = viewModel.person.description {
            Button {
                satellite.present(.description(viewModel.person))
            } label: {
                Text(description)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(alignment)
                    .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CompactPresentation: View {
    @Environment(PersonViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 8) {
            ItemImage(item: viewModel.person, size: .small, cornerRadius: .infinity)
                .frame(width: 120)

            Text(viewModel.person.name)
                .modifier(SerifModifier())
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            if viewModel.person.description != nil {
                DescriptionButton(alignment: .center, lineLimit: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            } else {
                Spacer(minLength: 8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RegularPresentation: View {
    @Environment(PersonViewModel.self) private var viewModel

    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            ItemImage(item: viewModel.person, size: .regular, cornerRadius: .infinity)
                .frame(width: 200)

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.person.name)
                    .modifier(SerifModifier())
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.leading)

                if viewModel.person.description != nil {
                    DescriptionButton(alignment: .leading, lineLimit: 5)
                }
            }
            .frame(minWidth: 280, maxWidth: 560, alignment: .leading)
        }
        .frame(maxWidth: 1000)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}
