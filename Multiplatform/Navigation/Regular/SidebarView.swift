//
//  SidebarView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPBase

struct SidebarView: View {
    @Default(.lastSidebarSelection) private var selection
    
    @State var libraries = [Library]()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if libraries.isEmpty {
                    ProgressView()
                        .task { await fetchLibraries() }
                } else {
                    ForEach(libraries) { library in
                        Section(library.name) {
                            ForEach(LibrarySection.filtered(libraryType: library.type), id: \.hashValue) { section in
                                NavigationLink(value: Selection(libraryId: library.id, section: section)) {
                                    Label(section.label, systemImage: section.icon)
                                }
                            }
                        }
                    }
                }
            }
            .modifier(NowPlaying.LeadingOffsetModifier())
            .modifier(AccountSheetToolbarModifier(requiredSize: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                            "offline": true,
                        ])
                    } label: {
                        Label("offline.enable", systemImage: "network.slash")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    selection.section.content
                        .id(selection.section)
                        .id(selection.libraryId)
                }
            } else {
                ContentUnavailableView("splitView.empty", systemImage: "bookmark.square.fill", description: Text("splitView.empty.description"))
            }
        }
        .modifier(NowPlaying.RegularBarModifier())
        .environment(\.libraryId, selection?.libraryId ?? "")
        .environment(AvailableLibraries(libraries: libraries))
    }
}

extension SidebarView {
    func fetchLibraries() async {
        if let libraries = try? await AudiobookshelfClient.shared.getLibraries(), !libraries.isEmpty {
            self.libraries = libraries
        }
    }
}

private extension Defaults.Keys {
    static let lastSidebarSelection = Key<SidebarView.Selection?>("lastSidebarSelection")
}

#Preview {
    SidebarView()
}
