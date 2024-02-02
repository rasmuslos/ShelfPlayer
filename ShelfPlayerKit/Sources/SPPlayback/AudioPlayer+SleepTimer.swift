//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation

public extension AudioPlayer {
    func setSleepTimer(duration: Double?) {
        audioPlayer.volume = 1
        
        pauseAtEndOfChapter = false
        remainingSleepTimerTime = duration
    }
    
    func setSleepTimer(endOfChapter: Bool) {
        pauseAtEndOfChapter = endOfChapter
        remainingSleepTimerTime = nil
    }
}
