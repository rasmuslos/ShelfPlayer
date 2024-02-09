//
//  PodcastSettingsSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import SwiftUI
import Defaults
import SPBase
import SPOffline
import SPOfflineExtended

struct PodcastSettingsSheet: View {
    let podcast: Podcast
    let configuration: PodcastFetchConfiguration
    
    @MainActor
    init(podcast: Podcast) {
        self.podcast = podcast
        configuration = OfflineManager.shared.requireConfiguration(podcastId: podcast.id)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("podcast.settings.autoDownload", isOn: .init(get: { configuration.autoDownload }, set: { configuration.autoDownload = $0 }))
                    Stepper("podcast.settings.maxEpisodes") {
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
                    Toggle("podcast.settings.notifications", isOn: .init(get: { configuration.notifications }, set: { configuration.notifications = $0 }))
                        .disabled(!configuration.autoDownload)
                } footer: {
                    Text("podcast.settings.notificationFooter")
                }
            }
            .navigationTitle(podcast.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PodcastSettingsSheet(podcast: .fixture)
        }
}
