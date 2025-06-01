//
//  CarPlayQueueController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
final class CarPlayQueueController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    var queue = [ItemIdentifier]()
    var upNextQueue = [ItemIdentifier]()
    
    var queueItems = [ItemIdentifier: CarPlayPlayableItemController]()
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: String(localized: "playback.queue"), sections: [], assistantCellConfiguration: .none)
        
        if #available(iOS 18.4, *) {
            template.showsSpinnerWhileEmpty = true
        }
        
        template.emptyViewTitleVariants = [String(localized: "loading")]
        
        update()
    }
    
    func update() {
        Task {
            queue = await AudioPlayer.shared.queue.map(\.itemID)
            upNextQueue = await AudioPlayer.shared.upNextQueue.map(\.itemID)
            
            updateSections()
            
            updateItems()
        }
    }
    
    private nonisolated func updateItems() {
        Task {
            var items = [ItemIdentifier: CarPlayPlayableItemController]()
            
            for (index, itemID) in await queue.enumerated() {
                guard await !queueItems.keys.contains(itemID) else {
                    continue
                }
                
                guard let item = try? await itemID.resolved as? PlayableItem else {
                    continue
                }
                
                items[itemID] = await CarPlayPlayableItemController(item: item, displayCover: true) {
                    Task {
                        await AudioPlayer.shared.skip(queueIndex: index)
                    }
                }
            }
            for (index, itemID) in await upNextQueue.enumerated() {
                guard await !queueItems.keys.contains(itemID) else {
                    continue
                }
                
                guard let item = try? await itemID.resolved as? PlayableItem else {
                    continue
                }
                
                items[itemID] = await CarPlayPlayableItemController(item: item, displayCover: true) {
                    Task {
                        await AudioPlayer.shared.skip(upNextQueueIndex: index)
                    }
                }
            }
            
            await MainActor.run {
                queueItems.merge(items) { $1 }
                updateSections()
            }
        }
    }
    private func updateSections() {
        template.updateSections([
            CPListSection(items: queue.enumerated().map { buildRow(for: $1, index: $0, isUpNextQueue: false) }, header: String(localized: "playback.queue"), sectionIndexTitle: nil),
            CPListSection(items: upNextQueue.enumerated().map { buildRow(for: $1, index: $0, isUpNextQueue: false) }, header: String(localized: "playback.upNextQueue"), sectionIndexTitle: nil),
        ])
    }
    
    private func buildRow(for itemID: ItemIdentifier, index: Int, isUpNextQueue: Bool) -> CPListItem {
        guard let controller = queueItems[itemID] else {
            return loadingRow
        }
        
        return controller.row
    }
    
    private var loadingRow: CPListItem {
        let row = CPListItem(text: String(localized: "loading"), detailText: nil, image: UIImage(systemName: "hourglass"))
        row.isEnabled = false
        
        return row
    }
}
