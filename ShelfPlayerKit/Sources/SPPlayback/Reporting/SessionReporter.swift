//
//  SessionReporter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation

protocol SessionReporter {
    func reportPlay() async
    func reportPause() async
    
    func notify(duration: TimeInterval, currentTime: TimeInterval) async
}
