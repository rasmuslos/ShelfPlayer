//
//  LibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import SPBaseKit

struct LibraryView: View {
    @State var libraries: [Library]?
    @State var activeLibrary: Library?
    
    var body: some View {
        if let libraries = libraries {
            if libraries.count > 0, let activeLibrary = activeLibrary {
                Group {
                    if activeLibrary.type == .audiobooks {
                        AudiobookLibraryView()
                    } else if activeLibrary.type == .podcasts {
                        PodcastLibraryView()
                    } else {
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
                ErrorView()
            }
        } else {
            LoadingView()
                .task {
                    libraries = (try? await AudiobookshelfClient.shared.getLibraries()) ?? []
                    
                    if let libraries = libraries {
                        if let id = Library.getLastActiveLibraryId(), let library = libraries.first(where: { $0.id == id }) {
                            setActiveLibrary(library)
                        } else if libraries.count > 0 {
                            setActiveLibrary(libraries[0])
                        }
                    }
                }
        }
    }
}

// MARK: Helper

extension LibraryView {
    func setActiveLibrary(_ library: Library) {
        activeLibrary = library
        library.setAsLastActiveLibrary()
    }
}

// MARK: Environment

struct LibraryIdDefault: EnvironmentKey {
    static var defaultValue: String = "cf50d37f-2bcb-45c9-abbd-455db93e4fc5"
}
extension EnvironmentValues {
    var libraryId: String {
        get { self[LibraryIdDefault.self] }
        set { self[LibraryIdDefault.self] = newValue }
    }
}


#Preview {
    LibraryView()
}
