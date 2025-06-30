//
//  SetSleepTimerIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation
import AppIntents

public struct SetSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.setSleepTimer"
    public static let description = IntentDescription("intent.setSleepTimer.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.setSleepTimer.amount", controlStyle: .field, inclusiveRange: (0, 43_200))
    public var amount: Int
    
    @Parameter(title: "intent.setSleepTimer.type")
    public var type: IntentSleepTimerType
    
    public init() {}
    public init(amount: Int, type: IntentSleepTimerType) {
        self.amount = amount
        self.type = type
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.setSleepTimer \(\.$amount) \(\.$type)")
    }
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        let configuration: SleepTimerConfiguration
        
        switch type {
            case .seconds:
                configuration = .interval(.now.addingTimeInterval(Double(amount)))
            case .minutes:
                configuration = .interval(.now.addingTimeInterval(Double(amount) * 60))
            case .hours:
                configuration = .interval(.now.addingTimeInterval(Double(amount) * 60 * 60))
            case .chapters:
                configuration = .chapters(amount)
        }
        
        await audioPlayer.setSleepTimer(configuration)
        
        return .result()
    }
}

public enum IntentSleepTimerType: Int, Codable, Sendable, CaseIterable, AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "intent.setSleepTimer.type")
    }
    
    public static var caseDisplayRepresentations: [IntentSleepTimerType : DisplayRepresentation] {[
        .seconds: DisplayRepresentation(title: "intent.setSleepTimer.type.seconds"),
        .minutes: DisplayRepresentation(title: "intent.setSleepTimer.type.minutes"),
        .hours: DisplayRepresentation(title: "intent.setSleepTimer.type.hours"),
        
        .chapters: DisplayRepresentation(title: "intent.setSleepTimer.type.chapters"),
    ]}
    
    case seconds
    case minutes
    case hours
    case chapters
}
