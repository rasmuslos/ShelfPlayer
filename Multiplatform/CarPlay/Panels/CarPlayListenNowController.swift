//
//  CarPlayListenNowController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback
final class CarPlayListenNowController {
    let template: CPListTemplate
    private var itemControllers = [CarPlayItemController]()
    private var refreshTask: Task<Void, Never>?
    init(interfaceController: CPInterfaceController) {
        template = CPListTemplate(
            title: String(localized: "panel.home"),
            sections: [],
            assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia)
        )
        template.tabTitle = String(localized: "panel.home")
        template.tabImage = UIImage(systemName: "house.fill")
        template.applyCarPlayLoadingState()
        RFNotification[.listenNowItemsChanged].subscribe { [weak self] in
            self?.reload()
        }
        RFNotification[.downloadStatusChanged].subscribe { [weak self] _ in
            self?.reload()
        }
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            self?.reload()
        }
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.reload()
        }
        reload()
    }
    deinit {
        refreshTask?.cancel()
    }
}
private extension CarPlayListenNowController {
    struct Snapshot {
        let offlineEnabled: Bool
        let listenNowItems: [PlayableItem]
        let downloadedAudiobooks: [Audiobook]
        let downloadedEpisodeGroups: [(Podcast, [Episode])]
    }
    func reload() {
        refreshTask?.cancel()
        template.applyCarPlayLoadingState()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            let snapshot = await self.loadSnapshot()
            guard !Task.isCancelled else {
                return
            }
            self.applySnapshot(snapshot)
        }
    }
    func loadSnapshot() async -> Snapshot {
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
        return .init(
            offlineEnabled: OfflineMode.shared.isEnabled,
            listenNowItems: listenNowItems,
            downloadedAudiobooks: downloadedAudiobooks,
            downloadedEpisodeGroups: downloadedEpisodeGroups
        )
    }
    func applySnapshot(_ snapshot: Snapshot) {
        var sections = [CPListSection]()
        var retainedControllers = [CarPlayItemController]()
        sections.append(
            CPListSection(items: [makeOfflineRow(offlineEnabled: snapshot.offlineEnabled)])
        )
        if !snapshot.listenNowItems.isEmpty {
            let controllers = snapshot.listenNowItems.map {
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
        if !snapshot.downloadedAudiobooks.isEmpty {
            let controllers = snapshot.downloadedAudiobooks.map {
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
        if !snapshot.downloadedEpisodeGroups.isEmpty {
            for (podcast, episodes) in snapshot.downloadedEpisodeGroups {
                let controllers = episodes.map {
                    CarPlayPlayableItemController(item: $0, displayCover: false)
                }
                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: podcast.name,
                        headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)),
                        headerImage: nil,
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
    func makeOfflineRow(offlineEnabled: Bool) -> CPListItem {
        let row = CPListItem(
            text: String(localized: offlineEnabled ? "navigation.offline.disable" : "navigation.offline.enable"),
            detailText: offlineEnabled ? "On" : "Off",
            image: UIImage(systemName: offlineEnabled ? "network.slash" : "network")
        )
        row.handler = { [weak self] listItem, completion in
            guard let self else {
                completion()
                return
            }
            Task {
                listItem.isEnabled = false
                if OfflineMode.shared.isEnabled {
                    await OfflineMode.shared.refreshAvailability()
                } else {
                    OfflineMode.shared.forceEnable()
                }
                self.reload()
                listItem.isEnabled = true
                completion()
            }
        }
        return row
    }
}
