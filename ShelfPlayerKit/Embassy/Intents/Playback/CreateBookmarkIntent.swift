//
//  CreateBookmarkIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct CreateBookmarkIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.createBookmark.title"
    public static let description = IntentDescription("intent.createBookmark.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.createBookmark.parameter.note.title",
               requestValueDialog: IntentDialog("intent.createBookmark.parameter.note.dialog"))
    public var note: String?

    public init() {}

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        try await audioPlayer.createBookmark(note)

        return .result()
    }
}
