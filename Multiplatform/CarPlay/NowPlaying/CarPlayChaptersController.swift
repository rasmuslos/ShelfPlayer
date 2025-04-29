//
//  CarPlayChaptersTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

@MainActor
class CarPlayChaptersController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: String(localized: "item.chapters"), sections: [], assistantCellConfiguration: .none)
        template.emptyViewTitleVariants = [String(localized: "playback.queue.empty")]
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] (_, chapters, startTime) in
            let index = chapters.firstIndex { $0.startOffset <= startTime && $0.endOffset > startTime }
            self?.updateSections(chapters: chapters, activeIndex: index)
        }
        RFNotification[.chapterChanged].subscribe { [weak self] _ in
            self?.update()
        }
        
        update()
    }
    
    private nonisolated func update() {
        Task {
            let chapters = await AudioPlayer.shared.chapters
            let activeChapterIndex = await AudioPlayer.shared.activeChapterIndex
            
            await self.updateSections(chapters: chapters, activeIndex: activeChapterIndex)
        }
    }
    private func updateSections(chapters: [Chapter], activeIndex: Int?) {
        self.template.updateSections([CPListSection(items: chapters.enumerated().map { index, chapter in
            let item =  CPListItem(text: chapter.title, detailText: chapter.timeOffsetFormatted)
            
            item.isPlaying = index == activeIndex
            item.playingIndicatorLocation = .trailing
            
            // item.handler = { [weak self] _, completion in
            item.handler = { _, completion in
                Task {
                    try await AudioPlayer.shared.seek(to: chapter.startOffset, insideChapter: false)
                    completion()
                }
            }
            
            return item
        })])
    }
}
