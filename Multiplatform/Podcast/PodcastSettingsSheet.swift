//
//  PodcastSettingsSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import SwiftUI
import Defaults
import SPFoundation
import SPOffline
import SPOfflineExtended

internal struct PodcastSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let podcast: Podcast
    let configuration: PodcastFetchConfiguration
    
    var body: some View {
        @Bindable var configuration = configuration
        
        List {
            Section {
                DownloadSettings(maxEpisodes: $configuration.maxEpisodes, autoDownloadEnabled: $configuration.autoDownload)
            } footer: {
                Text("podcast.settings.downloadFooter \(configuration.maxEpisodes)")
            }
            
            Section {
                NotificationToggle(autoDownloadEnabled: configuration.autoDownload, notificationsEnabled: $configuration.notifications)
            } footer: {
                Text("podcast.settings.notificationFooter")
            }
        }
        .padding(.top, -40)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("podcast.settings.title")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Label("dismiss", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .symbolVariant(.circle.fill)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .task(id: configuration) {
            if configuration.autoDownload {
                try? await BackgroundTaskHandler.updateDownloads(configuration: configuration)
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
            
            Stepper("podcast.settings.maxEpisodes \(maxEpisodes)") {
                if maxEpisodes <= 32 {
                    maxEpisodes += 1
                }
            } onDecrement: {
                if maxEpisodes > 1 {
                    maxEpisodes -= 1
                }
            }
            .disabled(!autoDownloadEnabled)
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
