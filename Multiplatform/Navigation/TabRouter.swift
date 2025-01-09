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
    @Environment(ConnectionStore.self) private var connectionStore
    
    @Binding var selection: TabValue?
    
    @State private var libraryPath = NavigationPath()
    
    var selectionProxy: Binding<TabValue?> {
        .init() { selection } set: {
            if $0 == selection, case .search = $0 {
                // NotificationCenter.default.post(name: SearchView.focusNotification, object: nil)
            }
            
            selection = $0
        }
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    private var current: Library? {
        guard isCompact else {
            return nil
        }
        
        return selection?.library
    }
    
    var body: some View {
        TabView(selection: selectionProxy) {
            if let current {
                ForEach(TabValue.tabs(for: current)) { tab in
                    Tab(tab.label, systemImage: tab.image, value: tab) {
                        tab.content(libraryPath: $libraryPath)
                    }
                }
            }
            ForEach(connectionStore.flat) { connection in
                if let libraries = connectionStore.libraries[connection.id] {
                    TabSection(connection.user) {
                        ForEach(libraries) {
                            ForEach(TabValue.tabs(for: $0)) { tab in
                                Tab(tab.label, systemImage: tab.image, value: tab) {
                                    tab.content(libraryPath: $libraryPath)
                                }
                                .hidden(isCompact)
                            }
                        }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .id(current)
        // .modifier(NowPlaying.CompactModifier())
        .onChange(of: current) {
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
        .onChange(of: selection?.library) {
            while !libraryPath.isEmpty {
                libraryPath.removeLast()
            }
        }
        .onChange(of: connectionStore.libraries, initial: true) {
            guard selection == nil, let library = connectionStore.libraries.first?.value.first else { return }
            
            switch library.type {
            case .audiobooks:
                selection = .audiobookHome(library)
            case .podcasts:
                selection = .podcastHome(library)
            default:
                return
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: TabValue? = nil
    
    TabRouter(selection: $selection)
        .environment(ConnectionStore())
}
