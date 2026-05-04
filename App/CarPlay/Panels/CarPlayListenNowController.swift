//
//  CarPlayListenNowController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
import Combine
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
final class CarPlayListenNowController {
    let template: CPListTemplate

    private var itemControllers = [CarPlayItemController]()
    private var refreshTask: Task<Void, Never>?
    private var observerSubscriptions = Set<AnyCancellable>()

    init() {
        template = CPListTemplate(
            title: String(localized: "panel.home"),
            sections: [],
            assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia)
        )

        template.tabTitle = String(localized: "panel.home")
        template.tabImage = UIImage(systemName: "house.fill")
        template.applyCarPlayLoadingState()

        Publishers.Merge4(
            PersistenceManager.shared.listenNow.events.itemsChanged,
            PersistenceManager.shared.download.events.statusChanged.map { _ in () },
            OfflineMode.events.changed.map { _ in () },
            PersistenceManager.shared.authorization.events.connectionsChanged.map { _ in () }
        )
        .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.reload()
        }
        .store(in: &observerSubscriptions)

        reload()
    }

    deinit {
        refreshTask?.cancel()
    }
}

private extension CarPlayListenNowController {
    func reload() {
        refreshTask?.cancel()
        template.applyCarPlayLoadingState()

        refreshTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let listenNowItems = (try? await PersistenceManager.shared.listenNow.current) ?? []
            let downloadedAudiobooks = ((try? await PersistenceManager.shared.download.audiobooks()) ?? []).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            let podcasts = ((try? await PersistenceManager.shared.download.podcasts()) ?? []).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            let episodes = (try? await PersistenceManager.shared.download.episodes()) ?? []
            let groupedEpisodes = Dictionary(grouping: episodes, by: \.podcastID)

            var downloadedEpisodeGroups = [(Podcast, [Episode])]()

            for podcast in podcasts {
                guard let contained = groupedEpisodes[podcast.id], !contained.isEmpty else {
                    continue
                }

                let sorted = await Podcast.filterSort(contained, podcastID: podcast.id)
                downloadedEpisodeGroups.append((podcast, sorted))
            }

            guard !Task.isCancelled else {
                return
            }

            var sections = [CPListSection(
                items: [makeOfflineRow(offlineEnabled: OfflineMode.shared.isEnabled)]
            )]
            var retainedControllers = [CarPlayItemController]()

            if !listenNowItems.isEmpty {
                let controllers = listenNowItems.map {
                    CarPlayPlayableItemController(item: $0, displayCover: true)
                }

                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: String(localized: "panel.listenNow"),
                        sectionIndexTitle: nil
                    )
                )
            }

            if !downloadedAudiobooks.isEmpty {
                let controllers = downloadedAudiobooks.map {
                    CarPlayPlayableItemController(item: $0, displayCover: true)
                }

                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: String(localized: "row.downloaded.audiobooks"),
                        sectionIndexTitle: nil
                    )
                )
            }

            if !downloadedEpisodeGroups.isEmpty {
                for (podcast, sortedEpisodes) in downloadedEpisodeGroups {
                    let controllers = sortedEpisodes.map {
                        CarPlayPlayableItemController(item: $0, displayCover: false)
                    }

                    retainedControllers.append(contentsOf: controllers)
                    sections.append(
                        CPListSection(
                            items: controllers.map(\.row),
                            header: podcast.name,
                            headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)),
                            headerImage: await podcast.id.platformImage(size: .small),
                            headerButton: nil,
                            sectionIndexTitle: nil
                        )
                    )
                }
            }

            itemControllers = retainedControllers
            template.updateSections(sections)
            template.applyCarPlayEmptyState()
        }
    }

    func makeOfflineRow(offlineEnabled: Bool) -> CPListItem {
        let row = CPListItem(
            text: offlineEnabled ? String(localized: "navigation.offline.disable") : String(localized: "navigation.offline.enable"),
            detailText: nil,
            image: UIImage(systemName: offlineEnabled ? "network.slash" : "network")
        )

        row.handler = { [weak self] listItem, completion in
            guard let self else {
                completion()
                return
            }

            Task {
                listItem.isEnabled = false

                if await OfflineMode.shared.isEnabled {
                    await OfflineMode.shared.refreshAvailability()
                } else {
                    await OfflineMode.shared.forceEnable()
                }

                self.reload()
                listItem.isEnabled = true
                completion()
            }
        }
        return row
    }
}
