//
//  CheckForDownloadsIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.06.25.
//

import Foundation
import AppIntents

public struct CheckForDownloadsIntent: ProgressReportingIntent {
    public static let title: LocalizedStringResource = "intent.checkForDownloads"
    public static let description = IntentDescription("intent.checkForDownloads.description")
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.checkForDownloads")
    }
    
    public func perform() async throws -> some IntentResult {
        progress.totalUnitCount = 100
        
        await withTaskCancellationHandler {
            await PersistenceManager.shared.convenienceDownload.scheduleAll()
        } onCancel: {
            PersistenceManager.shared.convenienceDownload.shouldComeToEnd = true
        }
        
        while !Task.isCancelled {
            try await Task.sleep(for: .seconds(0.4))
            
            let currentProgress = await PersistenceManager.shared.convenienceDownload.currentProgress
            progress.completedUnitCount = Int64(currentProgress * 100)
            
            guard currentProgress >= 1 else {
                continue
            }
            
            break
        }
        
        return .result()
    }
}

