//
//  SessionsImportView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct SessionsImportView: View {
    var callback: () -> ()
    
    @State var failed = false
    
    var body: some View {
        if !failed {
            LoadingView()
                .task {
                    do {
                        let cached = try await OfflineManager.shared.getCachedProgress(type: .localCached)
                        for progress in cached {
                            try await AudiobookshelfClient.shared.updateMediaProgress(itemId: progress.itemId, episodeId: progress.additionalId, currentTime: progress.currentTime, duration: progress.duration)
                            
                            progress.progressType = .localSynced
                        }
                        
                        let sessions = try await AudiobookshelfClient.shared.authorize()
                        await OfflineManager.shared.importSessions(sessions)
                        callback()
                        
                        try await OfflineManager.shared.deleteSyncedProgress()
                    } catch {
                        
                    }
                }
        } else {
            ErrorView()
        }
    }
}

#Preview {
    SessionsImportView() {
        print("import finished")
    }
}
