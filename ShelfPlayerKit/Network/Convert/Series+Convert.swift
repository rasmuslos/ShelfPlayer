//
//  Series+Convert.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "Series+Convert")

extension Series {
    convenience init(payload: ItemPayload, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) {
        let audiobooks = payload.books?.compactMap { Audiobook(payload: $0, libraryID: libraryID, connectionID: connectionID) } ?? []

        if let books = payload.books, !books.isEmpty, audiobooks.isEmpty {
            logger.debug("Series \(payload.id, privacy: .public) had \(books.count, privacy: .public) book payloads but none converted to audiobooks")
        }

        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: .series),
            name: payload.name!,
            authors: [],
            description: payload.description,
            addedAt: Date(timeIntervalSince1970: (payload.addedAt ?? 0) / 1000),
            audiobooks: audiobooks)
    }

    convenience init(item: ItemPayload, audiobooks: [ItemPayload], libraryID: LibraryIdentifier, connectionID: ItemIdentifier.ConnectionID) {
        var item = item
        item.books = audiobooks

        self.init(payload: item, libraryID: libraryID.libraryID, connectionID: connectionID)
    }
}

public extension Audiobook.SeriesFragment {
    static func parse(seriesName: String) -> [Self] {
        seriesName.split(separator: ", ").map {
            let parts = $0.split(separator: " #")

            if parts.count >= 2 {
                let name = parts[0...parts.count - 2].joined(separator: " #")

                if let sequence = Float(parts[parts.count - 1]) {
                    return Audiobook.SeriesFragment(id: nil, name: name, sequence: sequence)
                } else {
                    return Audiobook.SeriesFragment(id: nil, name: name.appending(" #").appending(parts[parts.count - 1]), sequence: nil)
                }
            } else {
                return Audiobook.SeriesFragment(id: nil, name: String($0), sequence: nil)
            }
        }
    }
}
