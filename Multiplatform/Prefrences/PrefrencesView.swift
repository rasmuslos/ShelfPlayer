//
//  PrefrencesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.03.25.
//

import SwiftUI

struct PrefrencesView: View {
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ConnectionPrefrences()
                } label: {
                    Label("connections", systemImage: "server.rack")
                }
                NavigationLink {
                    PlaybackRateEditor()
                } label: {
                    Label("playbackRates", systemImage: "percent")
                }
            }
            
            Section {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("account.settings", systemImage: "gear")
                }
                
                switch notificationPermission {
                case .notDetermined:
                    Button {
                        Task {
                            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                            notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                        }
                    } label: {
                        Label("account.notifications.request", systemImage: "bell.badge.waveform.fill")
                    }
                    .task {
                        notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                    }
                case .denied:
                    Link(destination: URL(string: UIApplication.openNotificationSettingsURLString)!) {
                        Label("account.notifications.denied", systemImage: "bell.slash.fill")
                    }
                    .foregroundStyle(.red)
                case .authorized:
                    Label("account.notifications.granted", systemImage: "bell.badge.fill")
                        .foregroundStyle(.secondary)
                default:
                    ProgressIndicator()
                }
            } footer: {
                Text("account.notifications.text")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                    Label("github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/Support.md")!) {
                    Label("support", systemImage: "lifepreserver")
                }
            }
        }
        .navigationTitle("prefrences")
        .foregroundStyle(.primary)
    }
}

private struct ConnectionPrefrences: View {
    var body: some View {
        List {
            ConnectionManager()
        }
        .navigationTitle("connections")
    }
}

#Preview {
    NavigationStack {
        PrefrencesView()
    }
    .previewEnvironment()
}
