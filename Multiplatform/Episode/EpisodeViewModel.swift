//
//  EpisodeViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import OSLog
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class EpisodeViewModel {
    private(set) var id = UUID()
    
    private(set) var episode: Episode
    var library: Library!
    
    var toolbarVisible = false
    var sessionsVisible = false
    
    private(set) var dominantColor: Color?
    
    let sessionLoader: SessionLoader
    
    private(set) var isChangingEpisodeType = false
    private(set) var notifyError = false
    
    init(episode: Episode) {
        self.episode = episode
        sessionLoader = .init(filter: .itemID(episode.id))
    }
}

extension EpisodeViewModel {
    var information: [(String, String)] {
        var information = [(String, String)]()
        
        information.append((ItemIdentifier.ItemType.podcast.label, episode.podcastName))
        information.append((String(localized: "item.author"), episode.authors.formatted(.list(type: .and, width: .narrow))))
        
        let episodeIndex = episode.index.episode
        if !episodeIndex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            information.append((String(localized: "item.index.episode"), episodeIndex))
        }
        
        if let season = episode.index.season, !season.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            information.append((String(localized: "item.index.season"), season))
        }
                
        if let releaseDate = episode.releaseDate {
            information.append((String(localized: "item.released"), releaseDate.formatted(date: .numeric, time: .shortened)))
        }
        
        return information
    }
//    var linkRanges: [NSRange<String.Index>: URL] {
//        guard let description = episode.description, let matches = episode.chapterMatches else {
//            return [:]
//        }
//        
//        return matches.compactMap {
//            let chapterTime = $0.1
//            return (, URL(string: "shelfPlayer://chapter?time=\(chapterTime)")!)
//        }
//    }
    
    nonisolated func load(refresh: Bool) {
        Task {
           await load(refresh: refresh)
        }
    }
    nonisolated func load(refresh: Bool) async {
        if refresh {
            try? await ShelfPlayer.refreshItem(itemID: self.episode.id)
        }
        
        await withTaskGroup {
            $0.addTask { await self.loadEpisode() }
            $0.addTask { await self.extractDominantColor() }
            
            if refresh {
                $0.addTask { await self.sessionLoader.refresh() }
            }
        }
        
        if refresh {
            await MainActor.run {
                id = .init()
            }
        }
    }
    
    nonisolated func changeEpisodeType(_ type: Episode.EpisodeType) {
        Task {
            let isRunning = await MainActor.run {
                let isRunning = isChangingEpisodeType
                isChangingEpisodeType = true
                
                return isRunning
            }
            
            guard !isRunning else {
                return
            }
            
            do {
                let episodeID = await episode.id
                try await ABSClient[episodeID.connectionID].setEpisodeType(type: type, for: episodeID)
                
                await load(refresh: true)
                
                await MainActor.run {
                    isChangingEpisodeType = false
                }
            } catch {
                await MainActor.run {
                    isChangingEpisodeType = false
                    notifyError.toggle()
                }
            }
        }
    }
}

extension Episode.EpisodeType {
    var label: String {
        switch self {
            case .regular: String(localized: "item.episode.type.regular")
            case .trailer: String(localized: "item.trailer")
            case .bonus: String(localized: "item.bonus")
        }
    }
}

private extension EpisodeViewModel {
    nonisolated func loadEpisode() async {
        do {
            guard let episode = try await episode.id.resolved as? Episode else {
                throw APIClientError.invalidItemType
            }
            
            await MainActor.withAnimation {
                self.episode = episode
            }
        } catch {
            await MainActor.run {
                notifyError.toggle()
            }
        }
    }
    nonisolated func extractDominantColor() async {
        let color = await PersistenceManager.shared.item.dominantColor(of: episode.id)
        
        await MainActor.withAnimation {
            self.dominantColor = color
        }
    }
}
