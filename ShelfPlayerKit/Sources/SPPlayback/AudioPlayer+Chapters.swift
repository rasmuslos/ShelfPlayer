//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SPFoundation

internal extension AudioPlayer {
    func updateChapterIndex() {
        if !enableChapterTrack || chapters.count <= 1 {
            activeChapterIndex = nil
            return
        }
        
        let currentTime = getItemCurrentTime()
        let chapter = chapters.firstIndex { $0.start <= currentTime && $0.end > currentTime }
        
        if pauseAtEndOfChapter && chapter != activeChapterIndex {
            sleepTimerDidExpire()
        }
        
        activeChapterIndex = chapter
    }
    
    // These are returned by the computed properties `duration` and `currentTime`
    
    func getChapterDuration() -> Double {
        if let chapter = getChapter() {
            return chapter.end - chapter.start
        } else {
            return getItemDuration()
        }
    }
    func getChapterCurrentTime() -> Double {
        let currentTime = getItemCurrentTime()
        
        if let chapter = getChapter() {
            return currentTime - chapter.start
        } else {
            return currentTime
        }
    }
    
    func getChapter() -> PlayableItem.Chapter? {
        if let activeChapterIndex = activeChapterIndex {
            return chapters[activeChapterIndex]
        } else {
            return nil
        }
    }
}
