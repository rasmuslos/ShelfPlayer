//
//  File.swift
//
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation

extension Podcast.PodcastType {
    static func convertFromAudiobookshelf(type: String?) -> Self? {
        guard let type = type else { return nil }
        
        if type == "episodic" {
            return .episodic
        } else if type == "serial" {
            return .serial
        }
        
        return nil
    }
}
