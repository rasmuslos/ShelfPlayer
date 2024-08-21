//
//  OfflineAudiobookTrack.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
public final class OfflineTrack {
    @Attribute(.unique)
    public let id: String
    public let parentId: String
    
    public let index: Int
    public let fileExtension: String
    
    public let offset: Double
    public let duration: Double
    
    public let type: ParentType
    public var downloadReference: Int?
    
    // this does not check for codec support... to bad (to be fair, i don't think the official ABS app does [https://github.com/advplyr/audiobookshelf-app/blob/master/ios/App/App/plugins/AbsDownloader.swift#L257])
    public init(id: String, parentId: String, index: Int, fileExtension: String, offset: Double, duration: Double, type: ParentType) {
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

public extension OfflineTrack {
    var isDownloaded: Bool {
        downloadReference == nil
    }
}
