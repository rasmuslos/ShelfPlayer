//
//  OfflineAudiobookTrack.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    public final class OfflineTrack {
        @Attribute(.unique)
        public var id: String
        public var parentId: String
        
        public var index: Int
        public var fileExtension: String
        
        public var offset: TimeInterval
        public var duration: TimeInterval
        
        public var type: ParentType
        public var downloadReference: Int?
        
        // this does not check for codec support... to bad (to be fair, i don't think the official ABS app does [https://github.com/advplyr/audiobookshelf-app/blob/master/ios/App/App/plugins/AbsDownloader.swift#L257])
        public init(id: String, parentId: String, index: Int, fileExtension: String, offset: TimeInterval, duration: TimeInterval, type: ParentType) {
            self.id = id
            self.parentId = parentId
            self.index = index
            self.fileExtension = fileExtension
            self.offset = offset
            self.duration = duration
            self.type = type
        }
        
        public enum ParentType: Codable {
            case episode
            case audiobook
        }
    }
}

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
public extension SchemaV1.OfflineTrack {
    var isDownloaded: Bool {
        downloadReference == nil
    }
}
