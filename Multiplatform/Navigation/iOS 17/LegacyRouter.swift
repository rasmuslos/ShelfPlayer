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
    
    @State private var current: Library?
    @State private var selection: TabValue?
    
    @State private var libraries: [Library] = []
    
    private var lastActiveLibrary: Library? {
        let lastActiveLibraryID = Defaults[.lastActiveLibraryID]
        return libraries.first { $0.id == lastActiveLibraryID }
    }
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
                        Tabs(current: current)
                    } else {
                        loadingPresentation
                    }
                } else {
                    
                }
            }
            .id(current)
            .environment(\.libraries, libraries)
            .modifier(NowPlaying.CompactModifier())
            .onChange(of: isCompact) {
                if isCompact {
                    current = selection?.library ?? lastActiveLibrary
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
                
                current = library
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
            current = lastActiveLibrary ?? libraries.first
            self.libraries = libraries
        }
    }
}
