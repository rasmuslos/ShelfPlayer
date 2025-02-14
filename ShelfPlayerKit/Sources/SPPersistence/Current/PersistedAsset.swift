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
    final class PersistedAsset {
        #Index<PersistedAsset>([\.id], [\._itemID], [\.downloadTaskID])
        #Unique<PersistedAsset>([\.id])
        // #Unique<PersistedAsset>([\.id], [\.itemID, \.fileType, \.index])
        
        @Attribute(.unique)
        private(set) var id = UUID()
        private(set) var _itemID: String
        
        private(set) var fileType: FileType
        
        var isDownloaded: Bool
        var downloadTaskID: Int?
        
        var progressWeight: Percentage
        
        init(itemID: ItemIdentifier, fileType: FileType, progressWeight: Percentage) {
            self.id = .init()
            
            _itemID = itemID.description
            self.fileType = fileType
            
            isDownloaded = false
            downloadTaskID = nil
            
            self.progressWeight = progressWeight
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
        var path: URL {
            var base: URL
            
            if ShelfPlayerKit.enableCentralized {
                base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.rfk.shelfplayer")!.appending(path: "DownloadV2")
            } else {
                base = URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "DownloadV2")
            }
            
            base.append(path: itemID.connectionID.replacing("/", with: "_"))
            base.append(path: itemID.libraryID)
            base.append(path: itemID.primaryID)
            
            try! FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            
            switch fileType {
            case .audio(_, _, let ino, let fileExtension):
                base.append(path: "\(ino).\(fileExtension)")
            case .pdf(let ino):
                base.append(path: "\(ino).pdf")
            case .image(let size):
                base.append(path: "\(size).png")
            }
            
            return base
        }
        
        enum FileType: Codable {
            case audio(offset: TimeInterval, duration: TimeInterval, ino: String, fileExtension: String)
            case pdf(ino: String)
            case image(size: ItemIdentifier.CoverSize)
        }
    }
}
