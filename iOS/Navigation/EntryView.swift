//
//  LibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import SPBase

struct EntryView: View {
    @State var failed = false
    @State var libraries = [Library]()
    @State var activeLibrary: Library?
    
    var body: some View {
        if let activeLibrary = activeLibrary, !libraries.isEmpty {
            Group {
                switch activeLibrary.type {
                    case .audiobooks:
                        AudiobookLibraryView()
                    case .podcasts:
                        PodcastLibraryView()
                    default:
                        ErrorView()
                }
            }
            .environment(\.libraryId, activeLibrary.id)
            .environment(AvailableLibraries(libraries: libraries))
            .onReceive(NotificationCenter.default.publisher(for: Library.libraryChangedNotification), perform: { notification in
                if let libraryId = notification.userInfo?["libraryId"] as? String, let library = libraries.first(where: { $0.id == libraryId }) {
                    setActiveLibrary(library)
                }
            })
        } else {
            if failed {
                ErrorView()
            } else {
                LoadingView()
                    .task { await fetchLibraries() }
            }
        }
    }
}

// MARK: Helper

extension EntryView {
    func fetchLibraries() async {
        if let libraries = try? await AudiobookshelfClient.shared.getLibraries(), !libraries.isEmpty {
            self.libraries = libraries
            
            if let id = Library.getLastActiveLibraryId(), let library = libraries.first(where: { $0.id == id }) {
                setActiveLibrary(library)
            } else if libraries.count > 0 {
                setActiveLibrary(libraries[0])
            }
        }
    }
    
    func setActiveLibrary(_ library: Library) {
        activeLibrary = library
        library.setAsLastActiveLibrary()
    }
}

// MARK: Environment

struct LibraryIdDefault: EnvironmentKey {
    static var defaultValue: String = ""
}
extension EnvironmentValues {
    var libraryId: String {
        get { self[LibraryIdDefault.self] }
        set { self[LibraryIdDefault.self] = newValue }
    }
}


#Preview {
    EntryView()
}
