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
    
    @ViewBuilder
    private var automaticDownloadContent: some View {
        if let configuration {
            @Bindable var configuration = configuration
            
            List {
                Section {
                    Toggle("item.preferences.automaticDownload.enabled", isOn: $configuration.enabled)
                    
                    Stepper("item.preferences.automaticDownload.amount \(configuration.amount)") {
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
                    Text("item.preferences.automaticDownload.footer \(configuration.amount)")
                }
                
                Section {
                    Toggle("item.preferences.automaticDownload.notificationsEnabled", isOn: $configuration.enableNotifications)
                        .disabled(notificationPermission != .authorized || !configuration.enabled)
                    
                    notificationPermissionButton
                }
            }
            .interactiveDismissDisabled()
        } else {
            LoadingView()
        }
    }
    private var notificationPermissionButton: some View {
        Group {
            if let notificationPermission {
                if notificationPermission == .notDetermined {
                    Button {
                        Task {
                            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                            self.notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                        }
                    } label: {
                        Label("notification.permission.request", systemImage: "bell.badge.waveform.fill")
                    }
                } else if notificationPermission != .authorized {
                    Label("notification.permission.denied", systemImage: "bell.slash.fill")
                        .foregroundStyle(.red)
                    
                    Button {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Label("item.preferences", systemImage: "gear")
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
        .navigationTitle("item.preferences.automaticDownloads")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    @Bindable var viewModel = viewModel
                    
                    List {
                        NavigationLink("item.preferences.automaticDownloads", destination: automaticDownloadContent)
                        
                        Section {
                            PlaybackRatePicker(label: "item.preferences.playbackRate", selection: $viewModel.playbackRate)
                            
                            Toggle(isOn: $viewModel.allowNextUpQueueGeneration) {
                                Text("item.preferences.allowUpNextQueueGeneration")
                            }
                        }
                    }
                    .sensoryFeedback(.error, trigger: notifyError)
                    .sensoryFeedback(.success, trigger: notifySuccess)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            if isLoading {
                                ProgressIndicator()
                            } else {
                                Button("action.save") {
                                    save()
                                }
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
            .navigationTitle("item.preferences")
            .navigationBarTitleDisplayMode(.inline)
        }
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

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PodcastConfigurationSheet(podcastID: .fixture)
        }
}
#endif
