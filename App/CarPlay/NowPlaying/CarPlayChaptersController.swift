//
//  CarPlayChaptersController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import Combine
@preconcurrency import CarPlay
import ShelfPlayback

final class CarPlayChaptersController {
    let template: CPListTemplate

    private var updateTask: Task<Void, Never>?
    private var observerSubscriptions = Set<AnyCancellable>()

    init() {
        template = CPListTemplate(
            title: String(localized: "item.chapters"),
            sections: [],
            assistantCellConfiguration: .none
        )

        template.applyCarPlayLoadingState()

        AudioPlayer.shared.events.playbackItemChanged
            .sink { [weak self] (_, chapters, startTime) in
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
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.chapterChanged
            .sink { [weak self] _ in
                Task { [weak self] in
                    self?.update()
                }
            }
            .store(in: &observerSubscriptions)

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

            guard !Task.isCancelled else {
                return
            }

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
