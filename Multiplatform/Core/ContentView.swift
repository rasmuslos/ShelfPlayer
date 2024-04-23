//
//  ContentView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import SwiftData
import SPBase
import Intents
import SPOffline

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var state: Step = AudiobookshelfClient.shared.isAuthorized ? .sessionImport : .login
    
    private var navigationController: some View {
        Group {
            if horizontalSizeClass == .compact {
                CompactEntryView()
            } else {
                SidebarView()
            }
        }
    }
    
    var body: some View {
        Group {
            switch state {
                case .login:
                    LoginView() {
                        state = .sessionImport
                    }
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
                        .onAppear {
                            VocabularyDonator.donateVocabulary()
                            
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
        .onReceive(NotificationCenter.default.publisher(for: Library.libraryChangedNotification), perform: { notification in
            if let offline = notification.userInfo?["offline"] as? Bool {
                state = offline ? .offline : .sessionImport
            }
        })
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
