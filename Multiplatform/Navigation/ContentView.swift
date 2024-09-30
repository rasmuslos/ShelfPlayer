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

internal struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Default(.tintColor) private var tintColor
    @Namespace private var namespace
    
    @State private var viewModel: NowPlaying.ViewModel = .init()
    @State private var step: Step = AudiobookshelfClient.shared.authorized ? .sessionImport : .login
    
    @ViewBuilder
    private var onlineContent: some View {
        Group {
            if #available(iOS 18, *) {
                TabRouter()
            } else {
                LegacyRouter()
            }
        }
        .onAppear {
            NetworkMonitor.shared.start() {
                step = .sessionImport
            }
            
            #if ENABLE_ALL_FEATURES
            INPreferences.requestSiriAuthorization { _ in }
            #endif
            
            Task.detached {
                try? await OfflineManager.shared.attemptListeningTimeSync()
                try? await UserContext.update()
            }
        }
        .onContinueUserActivity("io.rfk.shelfplayer.audiobook") { activity in
            guard let identifier = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            Navigation.navigate(audiobookID: identifier, libraryID: libraryID)
        }
        .onContinueUserActivity("io.rfk.shelfplayer.author") { activity in
            guard let identifier = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            Navigation.navigate(authorID: identifier, libraryID: libraryID)
        }
        .onContinueUserActivity("io.rfk.shelfplayer.series") { activity in
            guard let name = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            Navigation.navigate(seriesName: name, libraryID: libraryID)
        }
        .onContinueUserActivity("io.rfk.shelfplayer.podcast") { activity in
            guard let identifier = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            Navigation.navigate(podcastID: identifier, libraryID: libraryID)
        }
        .onContinueUserActivity("io.rfk.shelfplayer.episode") { activity in
            guard let identifier = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            let (podcastID, episodeID) = convertIdentifier(identifier: identifier)
            Navigation.navigate(episodeID: episodeID, podcastID: podcastID, libraryID: libraryID)
        }
    }
    
    var body: some View {
        Group {
            switch step {
            case .login:
                LoginView()
            case .sessionImport:
                SessionsImportView() {
                    step = $0 ? .online : .offline
                }
            case .online:
                onlineContent
            case .offline:
                OfflineView()
            }
        }
        .tint(tintColor.color)
        .environment(viewModel)
        .onAppear {
            viewModel.namespace = namespace
        }
        .onChange(of: AudiobookshelfClient.shared.authorized) {
            step = AudiobookshelfClient.shared.authorized ? .sessionImport : .login
        }
        .onReceive(NotificationCenter.default.publisher(for: SelectLibraryModifier.changeLibraryNotification)) { notification in
            if let offline = notification.userInfo?["offline"] as? Bool {
                step = offline ? .offline : .sessionImport
            }
        }
    }
    
    enum Step {
        case login
        case sessionImport
        case online
        case offline
    }
}

#Preview {
    ContentView()
}
