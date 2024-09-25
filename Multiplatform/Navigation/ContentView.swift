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
            
            Task {
                try await OfflineManager.shared.attemptListeningTimeSync()
            }
            
            #if ENABLE_ALL_FEATURES
            INPreferences.requestSiriAuthorization { _ in }
            #endif
        }
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
