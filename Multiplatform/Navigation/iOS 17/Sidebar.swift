//
//  Sidebar.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal struct Sidebar: View {
    let libraries: [Library]
    @Binding var selection: TabValue?
    @Binding var controller: NavigationController
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(libraries) { library in
                    Section(library.name, isExpanded: .constant(true)) {
                        ForEach(TabValue.tabs(for: library)) { tab in
                            NavigationLink(value: tab) {
                                Label(tab.label, systemImage: tab.image)
                            }
                        }
                    }
                }
            }
        } detail: {
            if let selection {
                selection.content(path: $controller[selection])
                    .id(selection.library)
            } else {
                ContentUnavailableView("splitView.empty", systemImage: "bookmark.square.fill", description: Text("splitView.empty.description"))
            }
        }
    }
}
