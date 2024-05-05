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
import SPBase
import SPOffline
import SPExtension

struct ContentView: View {
    @Default(.tintColor) private var tintColor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                            
                            let (podcastId, episodeId) = MediaResolver.shared.convertIdentifier(identifier: identifier)
                            Navigation.navigate(episodeId: episodeId, podcastId: podcastId)
                        }
                        .onAppear {
                            Task.detached { @MainActor in
                                try? await OfflineManager.shared.attemptPlaybackDurationSync()
                            }
                            
                            #if ENABLE_ALL_FEATURES
                            INPreferences.requestSiriAuthorization { _ in }
                            #endif
                        }
                case .offline:
                    OfflineView()
            }
        }
        .tint(tintColor.color)
        .onReceive(NotificationCenter.default.publisher(for: Library.libraryChangedNotification), perform: { notification in
            if let offline = notification.userInfo?["offline"] as? Bool {
                state = offline ? .offline : .sessionImport
            }
        })
        .onChange(of: AudiobookshelfClient.shared.authorized) {
            state = AudiobookshelfClient.shared.authorized ? .sessionImport : .login
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
