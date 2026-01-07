//
//  EpisodeDescription.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.26.
//

import SwiftUI
import ShelfPlayback

struct EpisodeDescription: View {
    @Environment(Satellite.self) private var satellite
    
    let episode: Episode
    
    var body: some View {
        Description(description: episode.description, showHeadline: false) { description in
            let text = description.string
            
            for match in text.matches(of: Episode.chapterTimestampRegex) {
                guard let timestamp = Episode.parseChapterTimestamp(String(match.output.1)) else {
                    continue
                }
                
                description.addAttributes([
                    .link: URL(string: "shelfPlayer://chapter/\(timestamp)")! as NSURL
                ], range: NSRange(match.range, in: text))
            }
        } handleURL: { url in
            if url.scheme == "shelfPlayer" && url.host() == "chapter" {
                guard url.pathComponents.count == 2 else {
                    return false
                }
                
                let timestamp = url.pathComponents[1]
                
                guard let time = TimeInterval(timestamp) else {
                    return false
                }
                
                if satellite.nowPlayingItemID == episode.id {
                    satellite.seek(to: time, insideChapter: false, completion: {})
                } else {
                    satellite.start(episode.id, at: time)
                }
                
                return false
            }
            
            return true
        }
    }
}

#if DEBUG
#Preview {
    EpisodeDescription(episode: .fixture)
        .border(.red)
        .previewEnvironment()
}
#endif
