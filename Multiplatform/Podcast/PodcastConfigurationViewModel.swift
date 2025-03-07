//
//  PodcastConfigurationViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.03.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

@MainActor @Observable
final class PodcastConfigurationViewModel: Sendable {
    let podcastID: ItemIdentifier
    
    var playbackRate: Percentage
    var allowNextUpQueueGeneration: Bool
    
    private let allowNextUpQueueGenerationDefault = true
    
    init(podcastID: ItemIdentifier) async {
        self.podcastID = podcastID
        
        playbackRate = await PersistenceManager.shared.podcasts.playbackRate(for: podcastID) ?? Defaults[.defaultPlaybackRate]
        allowNextUpQueueGeneration = await PersistenceManager.shared.podcasts.allowNextUpQueueGeneration(for: podcastID) ?? allowNextUpQueueGenerationDefault
    }
    
    func save() async throws {
         if playbackRate != Defaults[.defaultPlaybackRate] {
             try await PersistenceManager.shared.podcasts.setPlaybackRate(playbackRate, for: podcastID)
         } else {
             try await PersistenceManager.shared.podcasts.setPlaybackRate(nil, for: podcastID)
         }
        
        if allowNextUpQueueGeneration != allowNextUpQueueGenerationDefault {
            try await PersistenceManager.shared.podcasts.setAllowNextUpQueueGeneration(allowNextUpQueueGeneration, for: podcastID)
        } else {
            try await PersistenceManager.shared.podcasts.setAllowNextUpQueueGeneration(nil, for: podcastID)
        }
    }
}
