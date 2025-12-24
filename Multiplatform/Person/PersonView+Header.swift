//
//  AuthorView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import ShelfPlayback

extension PersonView {
    struct Header: View {
        @Environment(PersonViewModel.self) private var viewModel
        @Environment(Satellite.self) private var satellite
        
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
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(verbatim: "")
                        }
                    }
                
                if let description = viewModel.person.description {
                    Button {
                        satellite.present(.description(viewModel.person))
                    } label: {
                        Text(description)
                            .lineLimit(3)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                } else {
                    Spacer(minLength: 8)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
