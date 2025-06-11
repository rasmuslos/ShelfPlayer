//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import CoreTransferable
import SwiftSoup

public class Item: Identifiable, @unchecked Sendable, Codable {
    public let id: ItemIdentifier
    
    public let name: String
    public let authors: [String]
    
    public let description: String?
    
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?
    
    private var url: URL?
    
    init(id: ItemIdentifier, name: String, authors: [String], description: String?, genres: [String], addedAt: Date, released: String?) {
        self.id = id
        
        self.name = name
        self.authors = authors
        
        self.description = description
        
        self.genres = genres
        
        self.addedAt = addedAt
        self.released = released
        
        Task.detached {
            self.url = try? await id.url
        }
    }
}

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Item: Comparable {
    public static func <(lhs: Item, rhs: Item) -> Bool {
        lhs.sortName < rhs.sortName
    }
}

extension Item: Transferable {
    var transferableDescription: String {
        let subtitle: String
        let tertiaryTitle: String
        
        if id.isPlayable || id.type == .podcast {
            subtitle = authors.formatted(.list(type: .and, width: .short))
        } else {
            subtitle = id.type.label
        }
        
        if let audiobook = self as? Audiobook {
            tertiaryTitle = audiobook.narrators.formatted(.list(type: .and))
        } else if let episode = self as? Episode {
            tertiaryTitle = episode.podcastName
        } else if let podcast = self as? Podcast {
            tertiaryTitle = String(localized: "item.count.episodes.unplayed \(podcast.incompleteEpisodeCount ?? 0)")
        } else {
            tertiaryTitle = addedAt.formatted(date: .abbreviated, time: .standard)
        }
        
        if let descriptionText {
            return  """
                    \(name)
                    \(subtitle)
                    \(tertiaryTitle)
                    
                    \(descriptionText)
                    """
        } else {
            return  """
                    \(name)
                    \(subtitle)
                    \(tertiaryTitle)
                    """
        }
    }
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .init(exportedAs: "io.rfk.shelfPlayer.item"))
        
        ProxyRepresentation {
            $0.transferableDescription
        }
        ProxyRepresentation {
            $0.url ?? .temporaryDirectory
        }

        DataRepresentation(exportedContentType: .png) {
            guard let data = await $0.id.data(size: .large) else {
                throw TransferableError.missingImageData
            }
            
            return data
        }
    }
}

public extension Item {
    var sortName: String {
        get {
            var sortName = name.lowercased()
            
            if sortName.starts(with: "a ") {
                sortName = String(sortName.dropFirst(2))
            }
            if sortName.starts(with: "the ") {
                sortName = String(sortName.dropFirst(4))
            }
            
            sortName += " "
            sortName += authors.joined(separator: " ")
            
            return sortName
        }
    }
    
    var descriptionText: String? {
        guard let description = description, let document = try? SwiftSoup.parse(description) else {
            return nil
        }
        
        return try? document.text()
    }
}

private enum TransferableError: Error {
    case missingImageData
}
