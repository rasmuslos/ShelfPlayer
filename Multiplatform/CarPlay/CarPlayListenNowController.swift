//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

@MainActor
final class CarPlayListenNowController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    private var observedItemIDs = [ItemIdentifier]()
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: "carPlay.listenNow", sections: [], assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        template.tabTitle = "carPlay.listenNow"
        template.tabImage = UIImage(systemName: "house.fill")
        
        updateTemplate()
        
        RFNotification[.playbackItemChanged].subscribe {
            let (itemID, _, _) = $0
            
            guard self.observedItemIDs.contains(itemID) else {
                return
            }
            
            self.updateTemplate()
        }
    }
    
    nonisolated func updateTemplate() {
        Task {
            let listenNowItems = await ShelfPlayerKit.listenNowItems
            
            await MainActor.run {
                observedItemIDs = listenNowItems.map(\.id)
            }
            
            var listenNowRows = [CPListItem]()
            
            for item in listenNowItems {
                if let audiobook = item as? Audiobook {
                    await listenNowRows.append(CarPlayHelper.buildAudiobookListItem(audiobook))
                } else if let episode = item as? Episode {
                    await listenNowRows.append(CarPlayHelper.buildEpisodeListItem(episode, displayCover: true))
                }
            }
            
            let row = CPListSection(items: listenNowRows, header: "row.listenNow", sectionIndexTitle: nil)
            
            await template.updateSections([row])
        }
    }
}

/*
 if #available(iOS 18.4, *) {
     template.showsSpinnerWhileEmpty = true
 }
 */
