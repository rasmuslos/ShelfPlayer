//
//  LegacyRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@available(iOS, deprecated: 18.0, message: "Use `TabRouter` instead.")
internal struct LegacyRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.lastTabValue) private var selection
    @State private var current: Library?
    
    @State private var libraries: [Library] = []
    @State private var controller: NavigationController = .init()
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    @ViewBuilder
    private var loadingPresentation: some View {
        LoadingView()
            .task {
                await fetchLibraries()
            }
            .refreshable {
                await fetchLibraries()
            }
    }
    
    var body: some View {
        if !libraries.isEmpty {
            Group {
                if isCompact {
                    if let current {
                        Tabs(current: current, selection: $selection, controller: $controller)
                    } else {
                        loadingPresentation
                    }
                } else {
                    Sidebar(libraries: libraries, selection: $selection, controller: $controller)
                }
            }
            .id(current)
            .modifier(NowPlaying.CompactModifier())
            .environment(\.libraries, libraries)
            .environment(\.library, selection?.library ?? .init(id: "", name: "", type: .offline, displayOrder: -1))
            .onChange(of: isCompact) {
                if isCompact {
                    current = selection?.library ?? libraries.first
                } else {
                    current = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: SelectLibraryModifier.changeLibraryNotification)) {
                guard let userInfo = $0.userInfo as? [String: String], let libraryID = userInfo["libraryID"] else {
                    return
                }
                
                guard let library = libraries.first(where: { $0.id == libraryID }) else {
                    return
                }
                
                if isCompact {
                    current = library
                }
                
                if library.type == .audiobooks {
                    selection = .audiobookHome(library)
                } else if library.type == .podcasts {
                    selection = .podcastHome(library)
                }
            }
        } else {
            loadingPresentation
        }
    }
    
    private nonisolated func fetchLibraries() async {
        guard let libraries = try? await AudiobookshelfClient.shared.libraries() else {
            return
        }
        
        await MainActor.withAnimation {
            current = selection?.library ?? libraries.first
            self.libraries = libraries
        }
    }
}
