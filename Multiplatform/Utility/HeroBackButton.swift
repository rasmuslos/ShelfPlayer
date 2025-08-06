//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct HeroBackButton: View {
    @Environment(\.navigationContext) private var navigationContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ViewBuilder
    private var label: some View {
        Label("navigation.back", systemImage: "chevron.left")
            .labelStyle(.iconOnly)
    }
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
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
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    label
                }
            }
        }
    }
}
