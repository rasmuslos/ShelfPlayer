//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@available(iOS 18, *)
internal struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var current: Library? {
        didSet {
            let appearance = UINavigationBarAppearance()
            
            if current?.type == .audiobooks && Defaults[.useSerifFont] {
                appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
                appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            }
            
            appearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
    @State private var libraries: [Library] = []
    
    @State private var selection: TabValue?
    
    private var lastActiveLibrary: Library? {
        let lastActiveLibraryID = Defaults[.lastActiveLibraryID]
        return libraries.first { $0.id == lastActiveLibraryID }
    }
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        if !libraries.isEmpty {
            TabView(selection: $selection) {
                if let current {
                    ForEach(TabValue.tabs(for: current)) { tab in
                        Tab(tab.label, systemImage: tab.image, value: tab) {
                            tab.content
                        }
                        .hidden(!isCompact)
                    }
                }
                
                ForEach(libraries) { library in
                    TabSection(library.name) {
                        ForEach(TabValue.tabs(for: library)) { tab in
                            Tab(tab.label, systemImage: tab.image, value: tab) {
                                tab.content
                            }
                        }
                    }
                    .hidden(isCompact)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSidebarBottomBar {
                Button {
                    NotificationCenter.default.post(name: SelectLibraryModifier.changeLibraryNotification, object: nil, userInfo: [
                        "offline": true,
                    ])
                } label: {
                    Label("offline.enable", systemImage: "network.slash")
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
            LoadingView()
                .task {
                    await fetchLibraries()
                }
                .refreshable {
                    await fetchLibraries()
                }
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

@available(iOS 18, *)
#Preview {
    TabRouter()
        .environment(NowPlaying.ViewModel())
}
