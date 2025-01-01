//
//  PersistedAudioTrack.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedAudioTrack {
        // #Index<PersistedAudioTrack>([\.id], [\.parentID])
        // #Unique<PersistedAudioTrack>([\.id], [\.parentID, \.index])
        
        @Attribute(.unique)
        private(set) var id = UUID()
        private(set) var itemID: ItemIdentifier
        
        private(set) var index: Int
        
        private(set) var fileType: FileType
        
        private(set) var offset: TimeInterval
        private(set) var duration: TimeInterval
        
        var downloadTaskID: Int?
        
        init(id: UUID, itemID: ItemIdentifier, index: Int, fileType: FileType, offset: TimeInterval, duration: TimeInterval) {
            self.id = id
            self.itemID = itemID
            self.index = index
            self.fileType = fileType
            self.offset = offset
            self.duration = duration
            
            downloadTaskID = nil
        }
        
        enum FileType: Codable {
            case audio(fileExtension: String)
            case pdf
        }
    }
}
