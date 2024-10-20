//
//  CarPlayChaptersTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayChaptersController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    init(interfaceController: CPInterfaceController, audiobook: Audiobook) {
        self.interfaceController = interfaceController
        
        template = .init(title: audiobook.name, sections: [], assistantCellConfiguration: .none)
        updateSections()
    }
}

private extension CarPlayChaptersController {
    func updateSections() {
        let chapters = AudioPlayer.shared.chapters
        
        let items = chapters.map { chapter in
            let item = CPListItem(text: chapter.title,
                                  detailText: (chapter.end - chapter.start).formatted(.duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3)),
                                  image: nil)
            
            item.handler = { _, completion in
                Task {
                    await AudioPlayer.shared.seek(to: chapter.start)
                    completion()
                }
            }
            
            item.isPlaying = AudioPlayer.shared.chapter == chapter
            item.playingIndicatorLocation = .trailing
            
            return item
        }
        
        let section = CPListSection(items: items, header: nil, sectionIndexTitle: nil)
        self.template.updateSections([section])
    }
}
