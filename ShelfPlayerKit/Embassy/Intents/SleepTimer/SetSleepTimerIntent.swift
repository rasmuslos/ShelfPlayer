//
//  SetSleepTimerIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SetSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.setSleepTimer.title"
    public static let description = IntentDescription("intent.setSleepTimer.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.setSleepTimer.parameter.amount.title",
               controlStyle: .field,
               inclusiveRange: (0, 43_200),
               requestValueDialog: IntentDialog("intent.setSleepTimer.parameter.amount.dialog"))
    public var amount: Int

    @Parameter(title: "intent.setSleepTimer.parameter.type.title",
               requestValueDialog: IntentDialog("intent.setSleepTimer.parameter.type.dialog"))
    public var type: IntentSleepTimerType

    public init() {}

    public init(amount: Int, type: IntentSleepTimerType) {
        self.amount = amount
        self.type = type
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.setSleepTimer.summary \(\.$amount) \(\.$type)")
    }

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        let configuration: SleepTimerConfiguration

        switch type {
        case .seconds:
            configuration = .interval(Double(amount))
        case .minutes:
            configuration = .interval(Double(amount) * 60)
        case .hours:
            configuration = .interval(Double(amount) * 60 * 60)
        case .chapters:
            configuration = .chapters(amount)
        }

        await audioPlayer.setSleepTimer(configuration)

        return .result()
    }
}

public enum IntentSleepTimerType: Int, Codable, Sendable, CaseIterable, AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "intent.sleepTimer.unit")
    }

    public static var caseDisplayRepresentations: [IntentSleepTimerType: DisplayRepresentation] {[
        .seconds: DisplayRepresentation(title: "intent.sleepTimer.unit.seconds"),
        .minutes: DisplayRepresentation(title: "intent.sleepTimer.unit.minutes"),
        .hours: DisplayRepresentation(title: "intent.sleepTimer.unit.hours"),
        .chapters: DisplayRepresentation(title: "intent.sleepTimer.unit.chapters"),
    ]}

    case seconds
    case minutes
    case hours
    case chapters
}
