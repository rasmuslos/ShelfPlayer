//
//  CarPlay+Offline.swift
//  iOS
//
//  Created by Rasmus Krämer on 27.02.24.
//

import CarPlay
import SPPlayback
import SPOffline
import SPOfflineExtended

extension CarPlayDelegate {
    internal func buildOfflineListTemplate() async throws -> CPListTemplate {
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
        let podcasts = try OfflineManager.shared.podcasts()
        let audiobooks = try OfflineManager.shared.audiobooks()
        
        var sections: [CPListSection] = [
            .init(items: audiobooks.map { @MainActor in
                var image: UIImage?
                var detailText = ""
                
                if let imageUrl = $0.cover?.url, let data = try? Data(contentsOf: imageUrl) {
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
                
                item.playbackProgress = OfflineManager.shared.progressEntity(item: $0).progress
                
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
                
                item.playbackProgress = OfflineManager.shared.progressEntity(item: $0).progress
                
                return item
            }, header: $0.key.name, headerSubtitle: $0.key.author, headerImage: {
                if let imageUrl = $0.cover?.url, let data = try? Data(contentsOf: imageUrl) {
                    return UIImage(data: data)
                }
                
                return nil
            }($0.key), headerButton: nil, sectionIndexTitle: nil)
        })
        
        return sections
    }
}
