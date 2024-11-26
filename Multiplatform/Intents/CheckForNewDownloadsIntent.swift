//
//  CheckForNewDownloadsIntent.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.11.24.
//

import Foundation
import AppIntents

struct CheckForNewDownloadsIntent: AppIntent {
    static var title: LocalizedStringResource = "intents.checkForNewDownloads.title"
    static var description: IntentDescription? = "intents.checkForNewDownloads.description"
    
    func perform() async throws -> some IntentResult {
        try await BackgroundTaskHandler.updateDownloads()
        return .result()
    }
}