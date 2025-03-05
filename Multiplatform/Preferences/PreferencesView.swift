//
//  PreferencesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.03.25.
//

import SwiftUI
import ShelfPlayerKit

struct PreferencesView: View {
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ConnectionPreferences()
                } label: {
                    Label("connections", systemImage: "server.rack")
                }
                
                NavigationLink {
                    PlaybackRateEditor()
                } label: {
                    Label("playbackRates", systemImage: "percent")
                }
                NavigationLink {
                    SleepTimerEditor()
                } label: {
                    Label("sleepTimer", systemImage: "clock")
                }
                
                TintPicker()
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
            
            Section {
                Text("version \(ShelfPlayerKit.clientVersion) \(ShelfPlayerKit.clientBuild) \(ShelfPlayerKit.enableCentralized ? "C" : "L")")
                Text("version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
            }
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .navigationTitle("preferences")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(.primary)
    }
}

private struct ConnectionPreferences: View {
    var body: some View {
        List {
            ConnectionManager()
        }
        .navigationTitle("connections")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PreferencesView()
    }
    .previewEnvironment()
}
#endif
