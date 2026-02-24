//
//  CarPlayQueueController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback
final class CarPlayQueueController {
    let template: CPListTemplate
    private var itemControllers = [CarPlayItemController]()
    private var refreshTask: Task<Void, Never>?
    init(interfaceController: CPInterfaceController) {
        template = CPListTemplate(
            title: String(localized: "playback.queue"),
            sections: [],
            assistantCellConfiguration: .none
        )
        template.applyCarPlayLoadingState()
        update()
    }
    deinit {
        refreshTask?.cancel()
    }
    func update() {
        refreshTask?.cancel()
        template.applyCarPlayLoadingState()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            let queue = await AudioPlayer.shared.queue.map(\.itemID)
            let upNextQueue = await AudioPlayer.shared.upNextQueue.map(\.itemID)
            let queuePayload = await self.buildRows(for: queue, isUpNext: false)
            let upNextPayload = await self.buildRows(for: upNextQueue, isUpNext: true)
            self.itemControllers = queuePayload.controllers + upNextPayload.controllers
            var sections = [CPListSection]()
            if !queuePayload.rows.isEmpty {
                sections.append(
                    CPListSection(
                        items: queuePayload.rows,
                        header: String(localized: "playback.queue"),
                        sectionIndexTitle: nil
                    )
                )
            }
            if !upNextPayload.rows.isEmpty {
                sections.append(
                    CPListSection(
                        items: upNextPayload.rows,
                        header: String(localized: "playback.nextUpQueue"),
                        sectionIndexTitle: nil
                    )
                )
            }
            self.template.updateSections(sections)
            if queuePayload.rows.isEmpty && upNextPayload.rows.isEmpty {
                self.template.emptyViewTitleVariants = [String(localized: "playback.queue.empty")]
                self.template.emptyViewSubtitleVariants = [String(localized: "playback.queue.empty.description")]
                if #available(iOS 18.4, *) {
                    self.template.showsSpinnerWhileEmpty = false
                }
            }
        }
    }
}
private extension CarPlayQueueController {
    struct RowPayload {
        let rows: [CPListItem]
        let controllers: [CarPlayItemController]
    }
    func buildRows(for itemIDs: [ItemIdentifier], isUpNext: Bool) async -> RowPayload {
        var rows = [CPListItem]()
        var controllers = [CarPlayItemController]()
        for (index, itemID) in itemIDs.enumerated() {
            guard let item = try? await itemID.resolved as? PlayableItem else {
                rows.append(loadingRow)
                continue
            }
            let controller = CarPlayPlayableItemController(item: item, displayCover: true) {
                Task {
                    if isUpNext {
                        await AudioPlayer.shared.skip(upNextQueueIndex: index)
                    } else {
                        await AudioPlayer.shared.skip(queueIndex: index)
                    }
                }
            }
            controllers.append(controller)
            rows.append(controller.row)
        }
        return .init(rows: rows, controllers: controllers)
    }
    var loadingRow: CPListItem {
        let row = CPListItem(
            text: String(localized: "loading"),
            detailText: nil,
            image: UIImage(systemName: "hourglass")
        )
        row.isEnabled = false
        return row
    }
}
