//
//  LibraryEnumerator.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import ShelfPlayback

struct LibraryEnumerator<SectionLabel: View, Label: View>: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    @ViewBuilder let sectionLabel: (_ name: String, _ content: () -> AnyView) -> SectionLabel
    @ViewBuilder let label: (_ : Library) -> Label
    
    var body: some View {
        
        ForEach(connectionStore.connections) { connection in
            sectionLabel(connection.name) {
                AnyView(erasing: SectionInner(connectionID: connection.id, label: label))
            }
        }
    }
}

private struct SectionInner<Label: View>: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    let connectionID: ItemIdentifier.ConnectionID
    @ViewBuilder let label: (_ : Library) -> Label
    
    var body: some View {
        if let libraries = connectionStore.libraries[connectionID] {
            ForEach(libraries) {
                label($0)
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    LibraryEnumerator { name, content in
        Section(name) {
            content()
        }
    } label: {
        Text($0.name)
    }
    .previewEnvironment()
}
