//
//  PodcastSettingsSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let itemID: ItemIdentifier
    
    init(itemID: ItemIdentifier, current configuration: PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration) {
        self.itemID = itemID
        _configuration = .init(initialValue: .init(configuration))
    }
    
    @State private var loading = false
    
    @State private var configuration: PodcastAutoDownloadConfigurationShadow
    @State private var notificationPermission: UNAuthorizationStatus? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    DownloadSettings(maxEpisodes: $configuration.amount, autoDownloadEnabled: $configuration.enabled)
                    
                    Stepper("podcast.settings.maxEpisodes \(configuration.amount)") {
                        if configuration.amount <= 32 {
                            configuration.amount += 1
                        }
                    } onDecrement: {
                        if configuration.amount > 1 {
                            configuration.amount -= 1
                        }
                    }
                    .disabled(!configuration.enabled)
                } footer: {
                    Text("podcast.settings.downloadFooter \(configuration.amount)")
                }
                
                Section {
                    NotificationToggle(autoDownloadEnabled: configuration.enabled, notificationsEnabled: $configuration.enableNotifications)
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
                ToolbarItem(placement: .confirmationAction) {
                    if loading {
                        ProgressIndicator()
                    } else {
                        Button("save") {
                            Task {
                                loading = true
                                await PersistenceManager.shared.podcasts.set(itemID, configuration.materialized)
                                loading = false
                                
                                dismiss()
                                // try await BackgroundTaskHandler.(configuration: configuration)
                            }
                        }
                        .disabled(loading)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                    .disabled(loading)
                }
            }
        }
    }
}

extension UNNotificationSettings: @retroactive @unchecked Sendable {}

struct PodcastAutoDownloadConfigurationShadow: Codable, Sendable {
    var itemID: ItemIdentifier
    var enabled: Bool
    var amount: Int
    var enableNotifications: Bool
    
    init(_ configuration: PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration) {
        itemID = configuration.itemID
        enabled = configuration.enabled
        amount = configuration.amount
        enableNotifications = configuration.enableNotifications
    }
    
    var materialized: PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration {
        .init(itemID: itemID, enabled: enabled, amount: amount, enableNotifications: enableNotifications)
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
            PodcastSettingsSheet(itemID: .fixture, current: .init(itemID: .fixture,
                                                                  enabled: true,
                                                                  amount: 7,
                                                                  enableNotifications: true))
        }
}
#endif
