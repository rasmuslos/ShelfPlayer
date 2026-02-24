//
//  CarPlayChaptersController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback
final class CarPlayChaptersController {
    let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    init(interfaceController: CPInterfaceController) {
        template = CPListTemplate(
            title: String(localized: "item.chapters"),
            sections: [],
            assistantCellConfiguration: .none
        )
        template.applyCarPlayLoadingState()
        RFNotification[.playbackItemChanged].subscribe { [weak self] (_, chapters, startTime) in
            Task { [weak self] in
                guard let self else {
                    return
                }
                let index = chapters.firstIndex {
                    $0.startOffset <= startTime && $0.endOffset > startTime
                }
                self.updateSections(chapters: chapters, activeIndex: index)
            }
        }
        RFNotification[.chapterChanged].subscribe { [weak self] _ in
            Task { [weak self] in
                self?.update()
            }
        }
        update()
    }
    deinit {
        updateTask?.cancel()
    }
}
private extension CarPlayChaptersController {
    func update() {
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            guard let self else {
                return
            }
            let chapters = await AudioPlayer.shared.chapters
            let activeChapterIndex = await AudioPlayer.shared.activeChapterIndex
            self.updateSections(chapters: chapters, activeIndex: activeChapterIndex)
        }
    }
    func updateSections(chapters: [Chapter], activeIndex: Int?) {
        let items = chapters.enumerated().map { index, chapter in
            let row = CPListItem(text: chapter.title, detailText: chapter.timeOffsetFormatted)
            row.isPlaying = index == activeIndex
            row.playingIndicatorLocation = .trailing
            row.handler = { _, completion in
                Task {
                    try? await AudioPlayer.shared.seek(to: chapter.startOffset, insideChapter: false)
                    completion()
                }
            }
            return row
        }
        template.updateSections([CPListSection(items: items)])
        if chapters.isEmpty {
            template.emptyViewTitleVariants = [String(localized: "playback.queue.empty")]
            template.emptyViewSubtitleVariants = [String(localized: "playback.queue.empty.description")]
            if #available(iOS 18.4, *) {
                template.showsSpinnerWhileEmpty = false
            }
        }
    }
}
