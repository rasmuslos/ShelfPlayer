//
//  PodcastSettingsSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct PodcastSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let podcast: Podcast
    let configuration: PodcastFetchConfiguration
    
    @State private var notificationPermission: UNAuthorizationStatus? = nil
    
    var body: some View {
        @Bindable var configuration = configuration
        
        NavigationStack {
            List {
                Section {
                    DownloadSettings(maxEpisodes: $configuration.maxEpisodes, autoDownloadEnabled: $configuration.autoDownload)
                    
                    Stepper("podcast.settings.maxEpisodes \(configuration.maxEpisodes)") {
                        if configuration.maxEpisodes <= 32 {
                            configuration.maxEpisodes += 1
                        }
                    } onDecrement: {
                        if configuration.maxEpisodes > 1 {
                            configuration.maxEpisodes -= 1
                        }
                    }
                    .disabled(!configuration.autoDownload)
                } footer: {
                    Text("podcast.settings.downloadFooter \(configuration.maxEpisodes)")
                }
                
                Section {
                    NotificationToggle(autoDownloadEnabled: configuration.autoDownload, notificationsEnabled: $configuration.notifications)
                        .disabled(notificationPermission != .authorized)
                } footer: {
                    Text("podcast.settings.notificationFooter")
                }
                
                if let notificationPermission {
                    if notificationPermission == .notDetermined {
                        Button {
                            Task {
                                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                                self.notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                            }
                        } label: {
                            Label("account.notifications.request", systemImage: "bell.badge.waveform.fill")
                        }
                    } else if notificationPermission != .authorized {
                        Label("account.notifications.denied", systemImage: "bell.slash.fill")
                            .foregroundStyle(.red)
                        
                        Button {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        } label: {
                            Label("account.settings", systemImage: "gear")
                        }
                        .tint(.primary)
                    }
                } else {
                    ProgressIndicator()
                        .task {
                            notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                        }
                }
            }
            .navigationTitle("podcast.settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    dismiss()
                    
                    Task {
                        guard configuration.autoDownload else {
                            return
                        }
                        
                        try await BackgroundTaskHandler.updateDownloads(configuration: configuration)
                    }
                } label: {
                    Label("done", systemImage: "checkmark")
                        .labelStyle(.titleOnly)
                }
            }
            .onChange(of: configuration) {
                try? configuration.modelContext?.save()
            }
        }
    }
}

internal extension PodcastSettingsSheet {
    struct DownloadSettings: View {
        @Binding var maxEpisodes: Int
        @Binding var autoDownloadEnabled: Bool
        
        var body: some View {
            Toggle("podcast.settings.autoDownload", isOn: $autoDownloadEnabled)
        }
    }
    
    struct NotificationToggle: View {
        var autoDownloadEnabled: Bool
        @Binding var notificationsEnabled: Bool
        
        var body: some View {
            Toggle("podcast.settings.notifications", isOn: $notificationsEnabled)
                .disabled(!autoDownloadEnabled)
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PodcastSettingsSheet(podcast: .fixture, configuration: OfflineManager.shared.requireConfiguration(podcastId: "fixture"))
        }
}
#endif
