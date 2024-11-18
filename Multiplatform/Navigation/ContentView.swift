//
//  ContentView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Intents
import CoreSpotlight
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
        .modifier(SearchLibraryPicker())
        .onAppear {
            NetworkMonitor.start() {
                step = .sessionImport
            }
            
            Task {
                try? await OfflineManager.shared.attemptListeningTimeSync()
                try? await UserContext.run()
                
                try? await BackgroundTaskHandler.updateDownloads()
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) {
            guard let identifier = $0.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return
            }
            
            let data = convertIdentifier(identifier: identifier)
            
            guard let libraryID = data.libraryID else {
                return
            }
            
            switch data.type {
            case .audiobook:
                Navigation.navigate(audiobookID: data.itemID, libraryID: libraryID)
            case .author:
                Navigation.navigate(authorID: data.itemID, libraryID: libraryID)
            case .series:
                Navigation.navigate(seriesID: data.itemID, libraryID: libraryID)
            case .podcast:
                Navigation.navigate(podcastID: data.itemID, libraryID: libraryID)
            case .episode:
                guard let episodeID = data.episodeID else {
                    return
                }
                
                Navigation.navigate(episodeID: episodeID, podcastID: data.itemID, libraryID: libraryID)
            }
        }
        .onContinueUserActivity(CSQueryContinuationActionType) {
            guard let search = $0.userInfo?[CSSearchQueryString] as? String else {
                return
            }
            
            Search.shared.emit(library: nil, search: search)
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
            guard let identifier = activity.persistentIdentifier, let libraryID = activity.userInfo?["libraryID"] as? String else {
                return
            }
            
            Navigation.navigate(seriesID: identifier, libraryID: libraryID)
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
            
            let (podcastID, episodeID, _, _) = convertIdentifier(identifier: identifier)
            
            guard let episodeID else {
                return
            }
            
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
        .onReceive(AudiobookshelfClient.shared.$authorized) { authorized in
            step = authorized ? .sessionImport : .login
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
