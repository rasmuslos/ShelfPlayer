//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import Defaults
import SPBase
import SPPlayback
import SPOffline
import SPOfflineExtended

class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        Task {
            // Check if the user is logged in
            
            if !AudiobookshelfClient.shared.isAuthorized {
                try await interfaceController.presentTemplate(CPAlertTemplate(titleVariants: [String(localized: "carPlay.unauthorized.short"), String(localized: "carPlay.unauthorized")], actions: []), animated: true)
                
                return
            }
            
            updateNowPlayingTemplate()
            
            // Try to fetch libraries
            
            if false, let libraries = try? await AudiobookshelfClient.shared.getLibraries() {
                
            } else {
                try await interfaceController.setRootTemplate(try buildOfflineListTemplate(), animated: true)
            }
        }
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

extension CarPlayDelegate {
    private func buildOfflineListTemplate() async throws -> CPListTemplate {
        let template = CPListTemplate(title: String(localized: "carPlay.offline.title"), sections: try getOfflineSections(), assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                template.updateSections(Self.updateSections(template.sections))
            }
        }
        NotificationCenter.default.addObserver(forName: Self.updateContentNotifications, object: nil, queue: nil) { _ in
            Task { @MainActor in
                template.updateSections(Self.updateSections(template.sections))
            }
        }
        
        return template
    }
    
    private func getOfflineSections() throws -> [CPListSection] {
        let podcasts = try OfflineManager.shared.getPodcasts()
        let audiobooks = try OfflineManager.shared.getAudiobooks()
        
        var sections: [CPListSection] = [
            .init(items: audiobooks.map { @MainActor in
                var image: UIImage?
                var detailText = ""
                
                if let imageUrl = $0.image?.url, let data = try? Data(contentsOf: imageUrl) {
                    image = UIImage(data: data)
                }
                
                if let author = $0.author {
                    detailText += author
                }
                if let narrator = $0.narrator {
                    if !detailText.isEmpty {
                        detailText += " • "
                    }
                    
                    detailText += narrator
                }
                
                let item = CPListItem(text: $0.name, detailText: detailText.isEmpty ? nil : detailText, image: image, accessoryImage: nil, accessoryType: .none)
                
                item.isExplicitContent = $0.explicit
                
                item.playingIndicatorLocation = .trailing
                item.isPlaying = AudioPlayer.shared.item == $0
                
                item.userInfo = $0
                item.handler = Self.startPlayback
                
                item.playbackProgress = OfflineManager.shared.requireProgressEntity(item: $0).progress
                
                return item
            }, header: String(localized: "carPlay.offline.sections.audiobooks"), headerSubtitle: nil, headerImage: UIImage(systemName: "bookmark.fill"), headerButton: nil, sectionIndexTitle: nil),
        ]
        
        sections.append(contentsOf: podcasts.map {
            CPListSection(items: $0.value.map { @MainActor in
                let item = CPListItem(text: $0.name, detailText: $0.descriptionText)
                
                item.userInfo = $0
                item.handler = Self.startPlayback
                
                item.playingIndicatorLocation = .trailing
                item.isPlaying = AudioPlayer.shared.item == $0
                
                item.playbackProgress = OfflineManager.shared.requireProgressEntity(item: $0).progress
                
                return item
            }, header: $0.key.name, headerSubtitle: $0.key.author, headerImage: {
                if let imageUrl = $0.image?.url, let data = try? Data(contentsOf: imageUrl) {
                    return UIImage(data: data)
                }
                
                return nil
            }($0.key), headerButton: nil, sectionIndexTitle: nil)
        })
        
        return sections
    }
}

extension CarPlayDelegate {
    private static func startPlayback(item: CPSelectableListItem, completion: () -> Void) {
        (item.userInfo! as! PlayableItem).startPlayback()
        NotificationCenter.default.post(name: Self.updateContentNotifications, object: nil)
        
        completion()
    }
    
    private static func updateSections(_ sections: [CPListSection]) -> [CPListSection] {
        sections.map {
            CPListSection(items: $0.items.map {
                let item = $0 as! CPListItem
                let playableItem = $0.userInfo as! PlayableItem
                
                if AudioPlayer.shared.item == playableItem {
                    item.isPlaying = true
                    item.playbackProgress = OfflineManager.shared.requireProgressEntity(item: playableItem).progress
                } else {
                    item.isPlaying = false
                }
                
                return item
            }, header: $0.header!, headerSubtitle: $0.headerSubtitle, headerImage: $0.headerImage, headerButton: $0.headerButton, sectionIndexTitle: $0.sectionIndexTitle)
        }
    }
    
    private static let updateContentNotifications = NSNotification.Name("io.rfk.shelfplayer.carplay.update")
}

extension CarPlayDelegate {
    private func updateNowPlayingTemplate() {
        CPNowPlayingTemplate.shared.updateNowPlayingButtons([
            CPNowPlayingPlaybackRateButton() { _ in
                var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
                
                if rate > 2 {
                    rate = 0.25
                }
                
                AudioPlayer.shared.playbackRate = rate
            }
        ])
    }
}
