//
//  EpisodeViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import Combine
import OSLog
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class EpisodeViewModel {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "EpisodeViewModel")

    private var observerSubscriptions = Set<AnyCancellable>()

    private(set) var id = UUID()

    private(set) var episode: Episode
    var library: Library!

    var toolbarVisible = false

    let sessionLoader: SessionLoader

    private(set) var isChangingEpisodeType = false
    private(set) var notifyError = false

    init(episode: Episode) {
        self.episode = episode
        sessionLoader = .init(filter: .itemID(episode.id))

        ItemEventSource.shared.updated
            .sink { [weak self] connectionID, primaryID, groupingID in
                Task { @MainActor [weak self] in
                    guard let self, self.episode.id.matchesItemUpdate(connectionID: connectionID, primaryID: primaryID, groupingID: groupingID) else {
                        return
                    }

                    await self.load(refresh: true)
                }
            }
            .store(in: &observerSubscriptions)
    }
}

extension EpisodeViewModel {
    var information: [(String, String)] {
        var information = [(String, String)]()

        information.append((ItemIdentifier.ItemType.podcast.label, episode.podcastName))
        information.append((String(localized: "item.author"), episode.authors.formatted(.list(type: .and, width: .narrow))))

        let episodeIndex = episode.index.episode
        if !episodeIndex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            information.append((String(localized: "item.index.episode"), episodeIndex))
        }

        if let season = episode.index.season, !season.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            information.append((String(localized: "item.index.season"), season))
        }

        if let releaseDate = episode.releaseDate {
            information.append((String(localized: "item.released"), releaseDate.formatted(date: .numeric, time: .shortened)))
        }

        return information
    }

    func load(refresh: Bool) {
        Task {
           await load(refresh: refresh)
        }
    }
    func load(refresh: Bool) async {
        if refresh {
            do {
                try await ShelfPlayer.refreshItem(itemID: self.episode.id)
            } catch {
                logger.warning("Failed to refresh episode \(self.episode.id, privacy: .public): \(error, privacy: .public)")
            }
        }

        await withTaskGroup {
            $0.addTask { await self.loadEpisode() }

            if refresh {
                $0.addTask { await self.sessionLoader.refresh() }
            }
        }

        if refresh {
            id = .init()
        }
    }

    func changeEpisodeType(_ type: Episode.EpisodeType) {
        Task {
            let isRunning = isChangingEpisodeType
            isChangingEpisodeType = true

            guard !isRunning else {
                return
            }

            do {
                let episodeID = episode.id
                try await ABSClient[episodeID.connectionID].setEpisodeType(type: type, for: episodeID)

                try await Task.sleep(for: .seconds(1))

                await load(refresh: true)

                isChangingEpisodeType = false
            } catch {
                isChangingEpisodeType = false
                notifyError.toggle()
            }
        }
    }
}

extension Episode.EpisodeType {
    var label: String {
        switch self {
            case .regular: String(localized: "item.episode.type.regular")
            case .trailer: String(localized: "item.trailer")
            case .bonus: String(localized: "item.bonus")
        }
    }
}

private extension EpisodeViewModel {
    func loadEpisode() async {
        do {
            guard let episode = try await episode.id.resolved as? Episode else {
                throw APIClientError.invalidItemType
            }

            withAnimation {
                self.episode = episode
            }
        } catch {
            notifyError.toggle()
        }
    }
}
