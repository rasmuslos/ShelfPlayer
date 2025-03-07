//
//  PodcastSettingsSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let podcastID: ItemIdentifier
    
    @State private var viewModel: PodcastConfigurationViewModel?
    @State private var configuration: PodcastAutoDownloadConfigurationShadow?
    
    @State private var notificationPermission: UNAuthorizationStatus? = nil
    
    @State private var isLoading = false
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    var body: some View {
        NavigationStack {
            if let viewModel, let configuration {
                @Bindable var viewModel = viewModel
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
                    
                    Section {
                        PlaybackRatePicker(label: "playbackRate.default", selection: $viewModel.playbackRate)
                        Toggle(isOn: $viewModel.allowNextUpQueueGeneration) {
                            Text("podcast.configure.allowNextUpQueueGeneration")
                        }
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
                .navigationTitle("podcast.configure")
                .navigationBarTitleDisplayMode(.inline)
                .sensoryFeedback(.error, trigger: notifyError)
                .sensoryFeedback(.success, trigger: notifySuccess)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        if isLoading {
                            ProgressIndicator()
                        } else {
                            Button("save") {
                                save()
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel") {
                            dismiss()
                        }
                    }
                }
                .disabled(isLoading)
            } else {
                LoadingView()
                    .task {
                        await load()
                    }
                    .refreshable {
                        await load()
                    }
            }
        }
        .interactiveDismissDisabled()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    private func load() async {
        self.viewModel = await .init(podcastID: podcastID)
        self.configuration = .init(await PersistenceManager.shared.podcasts.configuration(for: podcastID))
    }
    private func save() {
        Task {
            isLoading = true
            
            do {
                if let viewModel {
                    try await viewModel.save()
                }
                if let configuration {
                    try await PersistenceManager.shared.podcasts.set(configuration: configuration.materialized, for: podcastID)
                }
                
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            isLoading = false
            
            dismiss()
            // try await BackgroundTaskHandler.(configuration: configuration)
        }
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

extension PodcastConfigurationSheet {
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
            PodcastConfigurationSheet(podcastID: .fixture)
        }
}
#endif
