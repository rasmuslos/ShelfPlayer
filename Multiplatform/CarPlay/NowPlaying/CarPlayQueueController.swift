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
    
    init() {
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
            
            let (queueRows, queueControllers) = await self.rows(for: queue, isUpNext: false)
            let (upNextRows, upNextControllers) = await self.rows(for: upNextQueue, isUpNext: true)
            
            guard !Task.isCancelled else {
                return
            }
            
            itemControllers = queueControllers + upNextControllers
            
            var sections = [CPListSection]()
            
            if !queueRows.isEmpty {
                sections.append(
                    CPListSection(
                        items: queueRows,
                        header: String(localized: "playback.queue"),
                        sectionIndexTitle: nil
                    )
                )
            }
            
            if !upNextRows.isEmpty {
                sections.append(
                    CPListSection(
                        items: upNextRows,
                        header: String(localized: "playback.nextUpQueue"),
                        sectionIndexTitle: nil
                    )
                )
            }
            
            template.updateSections(sections)
            
            if queueRows.isEmpty && upNextRows.isEmpty {
                template.emptyViewTitleVariants = [String(localized: "playback.queue.empty")]
                template.emptyViewSubtitleVariants = [String(localized: "playback.queue.empty.description")]
                
                if #available(iOS 18.4, *) {
                    template.showsSpinnerWhileEmpty = false
                }
            }
        }
    }
}

private extension CarPlayQueueController {
    func rows(for itemIDs: [ItemIdentifier], isUpNext: Bool) async -> ([CPListItem], [CarPlayItemController]) {
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
        
        return (rows, controllers)
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
