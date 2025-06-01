//
//  PlayIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents
import WidgetKit
import Defaults

public struct PlayIntent: AppIntent, AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.play"
    public static let description = IntentDescription("intent.play.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            let current = Defaults[.lastListened]
            Defaults[.lastListened] = .init(item: current?.item, isDownloaded: current?.isDownloaded ?? false, isPlaying: nil)
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
            
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.setPlaying(true)
        
        return .result()
    }
}
