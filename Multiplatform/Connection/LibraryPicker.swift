//
//  LibraryPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct LibraryPicker: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    
    
    var body: some View {
        ForEach(connectionStore.flat) { connection in
            if let libraries = connectionStore.libraries[connection.id] {
                Section {
                    ForEach(libraries) { library in
                        Button(library.name, systemImage: image(for: library)) {
                            
                        }
                    }
                } header: {
                    if connectionStore.connections.count > 1 {
                        Text(verbatim: "\(connection.host.formatted(.url.host())): \(connection.user)")
                    }
                }
            }
        }
    }
    
    private func image(for library: Library) -> String {
        if library.type == .podcasts {
            "antenna.radiowaves.left.and.right"
        } else {
            "headphones"
        }
    }
}

#Preview {
    Menu {
        LibraryPicker()
    } label: {
        Text(verbatim: "LibraryPicker")
    }
    .environment(ConnectionStore())
}
