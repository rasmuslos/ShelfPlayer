//
//  SessionsImportView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import OSLog

struct SessionsImportView: View {
    let logger = Logger(subsystem: "io.rfk.audiobooks", category: "SessionImport")
    
    var callback: (_ success: Bool) -> ()
    @State var task: Task<(), Error>?
    
    var body: some View {
        ProgressView {
            Button {
                task?.cancel()
                callback(false)
            } label: {
                Label("Go offline", systemImage: "network.slash")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
        }
        .onAppear {
            task = Task.detached {
                do {
                    let start = Date.timeIntervalSinceReferenceDate
                    let cached = try await OfflineManager.shared.getCachedProgress(type: .localCached)
                    for progress in cached {
                        try await AudiobookshelfClient.shared.updateMediaProgress(itemId: progress.itemId, episodeId: progress.additionalId, currentTime: progress.currentTime, duration: progress.duration)
                        
                        progress.progressType = .localSynced
                    }
                    logger.info("Synced progress to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
                    
                    try await OfflineManager.shared.deleteSyncedProgress()
                    logger.info("Deleted synced progress (took \(Date.timeIntervalSinceReferenceDate - start)s)")
                    
                    let sessions = try await AudiobookshelfClient.shared.authorize()
                    await OfflineManager.shared.importSessions(sessions)
                    
                    logger.info("Imported sessions (took \(Date.timeIntervalSinceReferenceDate - start)s)")
                    callback(true)
                } catch {
                    callback(false)
                }
            }
        }
    }
}

#Preview {
    SessionsImportView() { success in
        print("import finished", success)
    }
}
