//
//  OfflineAudiobookTrack.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
class OfflineAudiobookTrack {
    @Attribute(.unique)
    let id: String
    let audiobookId: String
    
    let index: Int
    
    let offset: Double
    let duration: Double
    
    var downloadCompleted: Bool
    
    // this does not check for codec support... to bad (to be fair, i don't think the official ABS app does [https://github.com/advplyr/audiobookshelf-app/blob/master/ios/App/App/plugins/AbsDownloader.swift#L257])
    init(id: String, audiobookId: String, index: Int, offset: Double, duration: Double) {
        self.id = id
        self.audiobookId = audiobookId
        self.index = index
        self.offset = offset
        self.duration = duration
        
        downloadCompleted = false
    }
}
