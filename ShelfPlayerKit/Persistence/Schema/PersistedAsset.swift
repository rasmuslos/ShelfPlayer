//
//  PersistedAsset.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedAsset {
        #Index<PersistedAsset>([\.id], [\._itemID], [\.downloadTaskID])
        #Unique<PersistedAsset>([\.id])

        @Attribute(.unique)
        public private(set) var id = UUID()
        public private(set) var _itemID: String

        public private(set) var fileType: FileType

        public var isDownloaded: Bool
        public var downloadTaskID: Int?

        public var progressWeight: Percentage

        public init(itemID: ItemIdentifier, fileType: FileType, progressWeight: Percentage) {
            self.id = .init()

            _itemID = itemID.description
            self.fileType = fileType

            isDownloaded = false
            downloadTaskID = nil

            self.progressWeight = progressWeight
        }

        public init(id: UUID, itemID: ItemIdentifier, fileType: FileType, isDownloaded: Bool, progressWeight: Percentage) {
            self.id = id

            _itemID = itemID.description
            self.fileType = fileType

            self.isDownloaded = isDownloaded
            downloadTaskID = nil

            self.progressWeight = progressWeight
        }

        public var itemID: ItemIdentifier {
            .init(string: _itemID)
        }

        public var fileExtension: String {
            switch fileType {
            case .audio(_, _, _, let fileExtension):
                fileExtension
            case .pdf:
                "pdf"
            case .image:
                "png"
            }
        }

        public var path: URL {
            var base = ShelfPlayerKit.downloadDirectoryURL

            base.append(path: itemID.connectionID.urlSafe)
            base.append(path: itemID.libraryID)
            base.append(path: itemID.primaryID)

            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

            base.append(path: "\(id).\(fileExtension)")

            return base
        }

        public enum FileType: Codable, Sendable {
            case audio(offset: TimeInterval, duration: TimeInterval, ino: String, fileExtension: String)
            case pdf(name: String, ino: String)
            case image(size: ImageSize)
        }
    }
}
