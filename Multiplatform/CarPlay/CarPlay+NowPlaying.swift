//
//  CarPlay+NowPlaying.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import Defaults
import SPPlayback

internal extension CarPlayDelegate {
    func updateNowPlayingTemplate() -> NowPlayingObserver {
        CPNowPlayingTemplate.shared.updateNowPlayingButtons([
            CPNowPlayingPlaybackRateButton() { _ in
                var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
                
                if rate > 2 {
                    rate = 0.25
                }
                
                AudioPlayer.shared.playbackRate = rate
            }
        ])
        
        CPNowPlayingTemplate.shared.upNextTitle = String(localized: "carPlay.chapters")
        CPNowPlayingTemplate.shared.isUpNextButtonEnabled = true
        
        let observer = NowPlayingObserver(interfaceController: interfaceController)
        CPNowPlayingTemplate.shared.add(observer)
        
        return observer
    }
    
    final class NowPlayingObserver: NSObject, CPNowPlayingTemplateObserver {
        private var interfaceController: CPInterfaceController?
        
        init(interfaceController: CPInterfaceController?) {
            self.interfaceController = interfaceController
        }
        
        func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
            Task {
                if AudioPlayer.shared.chapters.count > 1 {
                    try await interfaceController?.pushTemplate(CPListTemplate(title: .init(localized: "carPlay.chapters.title"), sections: [
                        .init(items: AudioPlayer.shared.chapters.map { chapter in
                            let item = CPListItem(
                                text: chapter.title,
                                detailText: (chapter.end - chapter.start).hoursMinutesSecondsString(includeSeconds: true, includeLabels: false))
                            
                            item.handler = { _, completion in
                                AudioPlayer.shared.seek(to: chapter.start)
                                Task {
                                    try await self.interfaceController?.popTemplate(animated: true)
                                    completion()
                                }
                            }
                            
                            item.isPlaying = AudioPlayer.shared.chapter == chapter
                            
                            return item
                        })
                    ]), animated: true)
                } else {
                    try await interfaceController?.presentTemplate(CPAlertTemplate(titleVariants: [.init(localized: "carPlay.chapters.empty.short"), .init(localized: "carPlay.chapters.empty")], actions: [
                        .init(title: .init(localized: "carPlay.chapters.dismiss"), style: .cancel) { _ in
                            Task {
                                try? await self.interfaceController?.dismissTemplate(animated: true)
                            }
                        }
                    ]), animated: true)
                }
            }
        }
    }
}
