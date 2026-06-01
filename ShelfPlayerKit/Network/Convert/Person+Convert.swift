//
//  Person+Convert.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "Person+Convert")

extension Person {
    convenience init?(author: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        guard let libraryID = author.libraryId else {
            logger.warning("Skipping author conversion for \(author.id, privacy: .public): missing libraryId")
            return nil
        }
        guard let name = author.name else {
            logger.warning("Skipping author conversion for \(author.id, privacy: .public): missing name")
            return nil
        }

        let addedAt = author.addedAt ?? 0

        self.init(
            id: .init(primaryID: author.id, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: .author),
            name: name,
            description: author.description,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            bookCount: author.numBooks ?? 0)
    }

    convenience init(narrator: NarratorResponse, libraryID: String, connectionID: ItemIdentifier.ConnectionID) {
        let id: ItemIdentifier

        if let provided = narrator.id {
            id = ItemIdentifier(primaryID: provided, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: .narrator)
        } else {
            id = Self.convertNarratorToID(narrator.name, libraryID: libraryID, connectionID: connectionID)
        }

        self.init(
            id: id,
            name: narrator.name,
            description: nil,
            addedAt: .distantPast,
            bookCount: narrator.numBooks)
    }

    public static func convertNarratorToID(_ narrator: String, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) -> ItemIdentifier {
        var base64 = Data(narrator.utf8).base64EncodedString()

        base64 = base64.replacingOccurrences(of: "+", with: "%2B")
        base64 = base64.replacingOccurrences(of: "/", with: "%2F")
        base64 = base64.replacingOccurrences(of: "=", with: "%3D")

        return ItemIdentifier(primaryID: base64,
                              groupingID: nil,
                              libraryID: libraryID,
                              connectionID: connectionID,
                              type: .narrator)
    }
}
