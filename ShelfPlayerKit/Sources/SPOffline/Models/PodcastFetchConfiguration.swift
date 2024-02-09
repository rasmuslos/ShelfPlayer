//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 09.02.24.
//

import Foundation
import SwiftData

@Model
public class PodcastFetchConfiguration {
    @Attribute(.unique)
    public let id: String
    
    public var autoDownload: Bool
    public var maxEpisodes: Int
    public var notifications: Bool
    
    public init(id: String) {
        self.id = id
        
        autoDownload = false
        maxEpisodes = 3
        notifications = false
    }
}
