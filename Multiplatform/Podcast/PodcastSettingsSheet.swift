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
    
    let podcastID: ItemIdentifier
    
    @State private var loading = false
    
    @State private var configuration: PodcastAutoDownloadConfigurationShadow?
    @State private var notificationPermission: UNAuthorizationStatus? = nil
    
    var body: some View {
        NavigationStack {
            if let configuration {
                @Bindable var configuration = configuration
                
                List {
                    Section {
                        EnabledToggle(enabled: $configuration.enabled)
                        MaxEpisodesStepper(amount: $configuration.amount)
                            .disabled(!configuration.enabled)
                    } footer: {
                        Text("podcast.settings.downloadFooter \(configuration.amount)")
                    }
                    
                    Section {
                        NotificationToggle(notificationsEnabled: $configuration.enableNotifications)
                            .disabled(notificationPermission != .authorized || !configuration.enabled)
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
                .disabled(loading)
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
                                    await PersistenceManager.shared.podcasts.set(podcastID, configuration.materialized)
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
            } else {
                LoadingView()
                    .task {
                        await fetchConfiguration()
                    }
                    .refreshable {
                        await fetchConfiguration()
                    }
            }
        }
    }
    
    private func fetchConfiguration() async {
        self.configuration = .init(await PersistenceManager.shared.podcasts[podcastID])
    }
}

extension UNNotificationSettings: @retroactive @unchecked Sendable {}

@MainActor @Observable
private final class PodcastAutoDownloadConfigurationShadow: Sendable {
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

extension PodcastSettingsSheet {
    struct EnabledToggle: View {
        @Binding var enabled: Bool
        
        var body: some View {
            Toggle("podcast.settings.autoDownload", isOn: $enabled)
        }
    }
    
    struct MaxEpisodesStepper: View {
        @Binding var amount: Int
        
        var body: some View {
            Stepper("podcast.settings.maxEpisodes \(amount)") {
                if amount <= 32 {
                    amount += 1
                }
            } onDecrement: {
                if amount > 1 {
                    amount -= 1
                }
            }
        }
    }
    
    struct NotificationToggle: View {
        @Binding var notificationsEnabled: Bool
        
        var body: some View {
            Toggle("podcast.settings.notifications", isOn: $notificationsEnabled)
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PodcastSettingsSheet(podcastID: .fixture)
        }
}
#endif
