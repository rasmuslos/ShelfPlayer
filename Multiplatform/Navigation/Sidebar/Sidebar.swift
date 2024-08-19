//
//  SidebarView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPFoundation

struct Sidebar: View {
    @Default(.sidebarSelection) private var selection
    
    @State var libraries = [Library]()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if libraries.isEmpty {
                    ProgressIndicator()
                        .task { await fetchLibraries() }
                } else {
                    ForEach(libraries) { library in
                        Section(library.name) {
                            ForEach(Panel.filtered(libraryType: library.type), id: \.hashValue) { panel in
                                NavigationLink(value: Selection(libraryId: library.id, panel: panel)) {
                                    Label(panel.label!, systemImage: panel.icon!)
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
                    selection.panel.content
                        .id(selection.panel)
                        .id(selection.libraryId)
                }
            } else {
                ContentUnavailableView("splitView.empty", systemImage: "bookmark.square.fill", description: Text("splitView.empty.description"))
            }
        }
        .modifier(NowPlaying.RegularBarModifier())
        .environment(\.libraryId, selection?.libraryId ?? "")
        .environment(AvailableLibraries(libraries: libraries))
        .modifier(Navigation.NotificationModifier(
            navigateAudiobook: {
                selection = .init(libraryId: $1, panel: .audiobook(id: $0))
            }, navigateAuthor: {
                selection = .init(libraryId: $1, panel: .author(id: $0))
            }, navigateSeries: {
                selection = .init(libraryId: $1, panel: .singleSeries(name: $0))
            }, navigatePodcast: {
                selection = .init(libraryId: $1, panel: .podcast(id: $0))
            }, navigateEpisode: {
                selection = .init(libraryId: $2, panel: .episode(id: $0, podcastId: $1))
            }))
    }
    
    private func fetchLibraries() async {
        if let libraries = try? await AudiobookshelfClient.shared.getLibraries(), !libraries.isEmpty {
            self.libraries = libraries
        }
    }
}

#Preview {
    Sidebar()
}
