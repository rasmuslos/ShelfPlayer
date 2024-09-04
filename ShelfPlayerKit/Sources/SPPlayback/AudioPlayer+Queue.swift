//
//  AudioPlayer+Queue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.09.24.
//

import Foundation
import SPFoundation

public extension AudioPlayer {
    func queue(_ item: PlayableItem) {
        if self.item == nil && queue.isEmpty {
            Task {
                try await play(item, queue: [])
            }
            
            return
        }
        
        queue.append(item)
    }
    
    /// A function that moves a queued item from the `from` index to the `to` position
    func move(from: Int, to: Int) {
        guard queue.count > from else {
            return
        }
        
        var copy = queue
        let to = min(to, queue.count)
        
        let track = copy.remove(at: from)
        
        if from > to {
            queue.insert(track, at: to)
        } else {
            queue.insert(track, at: to - 1)
        }
        
        queue = copy
    }
    
    func remove(at index: Int) {
        queue.remove(at: index)
    }
    
    func clear() {
        queue = []
    }
}
