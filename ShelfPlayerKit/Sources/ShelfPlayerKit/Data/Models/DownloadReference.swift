//
//  DownloadReference.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
class DownloadReference {
    var downloadTask: Int!
    let reference: String
    
    let type: ReferenceType
    
    init(reference: String, type: ReferenceType) {
        self.reference = reference
        self.type = type
        
        downloadTask = nil
    }
}

// MARK: Helper

extension DownloadReference {
    enum ReferenceType: Int, Codable {
        case audiobook = 0
        case episode = 1
    }
}
