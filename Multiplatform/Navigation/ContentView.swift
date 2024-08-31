//
//  ContentView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Intents
import SwiftData
import Defaults
import ShelfPlayerKit

struct ContentView: View {
    @Namespace private var namespace
    @Default(.tintColor) private var tintColor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var viewModel: NowPlaying.ViewModel = .init()
    @State private var state: Step = AudiobookshelfClient.shared.authorized ? .sessionImport : .login
    
    private var navigationController: some View {
        Group {
            if horizontalSizeClass == .compact {
                Tabs()
            } else {
                Sidebar()
            }
        }
    }
    
    var body: some View {
        Group {
            switch state {
                case .login:
                    LoginView()
                case .sessionImport:
                    SessionsImportView() { success in
                        if success {
                            state = .library
                        } else {
                            state = .offline
                        }
                    }
                case .library:
                    navigationController
                        .environment(viewModel)
                        .onContinueUserActivity("io.rfk.shelfplayer.audiobook") { activity in
                            guard let identifier = activity.persistentIdentifier else {
                                return
                            }
                            
                            Navigation.navigate(audiobookId: identifier)
                        }
                        .onContinueUserActivity("io.rfk.shelfplayer.author") { activity in
                            guard let identifier = activity.persistentIdentifier else {
                                return
                            }
                            
                            Navigation.navigate(authorId: identifier)
                        }
                        .onContinueUserActivity("io.rfk.shelfplayer.series") { activity in
                            guard let name = activity.persistentIdentifier else {
                                return
                            }
                            
                            Navigation.navigate(seriesName: name)
                        }
                        .onContinueUserActivity("io.rfk.shelfplayer.podcast") { activity in
                            guard let identifier = activity.persistentIdentifier else {
                                return
                            }
                            
                            Navigation.navigate(podcastId: identifier)
                        }
                        .onContinueUserActivity("io.rfk.shelfplayer.episode") { activity in
                            guard let identifier = activity.persistentIdentifier else {
                                return
                            }
                            
                            let (podcastId, episodeId) = convertIdentifier(identifier: identifier)
                            Navigation.navigate(episodeId: episodeId, podcastId: podcastId)
                        }
                        .onAppear {
                            Task.detached { @MainActor in
                                try? await OfflineManager.shared.attemptListeningTimeSync()
                            }
                            
                            NetworkMonitor.shared.start() {
                                state = .sessionImport
                            }
                            
                            #if ENABLE_ALL_FEATURES
                            INPreferences.requestSiriAuthorization { _ in }
                            #endif
                        }
                case .offline:
                    OfflineView()
                        .environment(viewModel)
            }
        }
        .tint(tintColor.color)
        .onAppear {
            viewModel.namespace = namespace
        }
        .onChange(of: AudiobookshelfClient.shared.authorized) {
            state = AudiobookshelfClient.shared.authorized ? .sessionImport : .login
        }
        .onReceive(NotificationCenter.default.publisher(for: Library.changeLibraryNotification)) { notification in
            if let offline = notification.userInfo?["offline"] as? Bool {
                state = offline ? .offline : .sessionImport
            }
        }
    }
}

// MARK: Helper

extension ContentView {
    enum Step {
        case login
        case sessionImport
        case library
        case offline
    }
}

#Preview {
    ContentView()
}
