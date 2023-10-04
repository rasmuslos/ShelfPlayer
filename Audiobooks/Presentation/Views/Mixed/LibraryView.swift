//
//  LibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LibraryView: View {
    @State var libraries: [Library]?
    @State var activeLibrary: Library?
    
    var body: some View {
        if let libraries = libraries {
            if libraries.count > 0, let activeLibrary = activeLibrary {
                Group {
                    if activeLibrary.type == .audiobooks {
                        AudiobookLibraryView(library: activeLibrary)
                    } else if activeLibrary.type == .podcasts {
                        
                    } else {
                        ErrorView()
                    }
                }
                .environment(\.libraryId, activeLibrary.id)
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

// MARK: View Model

extension LibraryView {
    @Observable
    class LibraryViewModel {
        
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
    LibraryView()
}
