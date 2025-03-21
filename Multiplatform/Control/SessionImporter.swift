//
//  SessionsImportView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import OSLog
import SPFoundation
import SPPersistence

struct SessionImporter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let connectionID: ItemIdentifier.ConnectionID
    let callback: @MainActor (_ success: Bool) -> ()
    
    @State private var task: Task<(), Error>?
    
    var body: some View {
        ContentUnavailableView("sessions.importing", systemImage: "binoculars")
            .symbolEffect(.pulse)
            .safeAreaInset(edge: .bottom) {
                Menu("library.change") {
                    LibraryPicker() {
                        task?.cancel()
                        callback(false)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .onAppear {
                task = Task.detached {
                    let success: Bool
                    
                    do {
                        let (sessions, bookmarks) = try await ABSClient[connectionID].authorize()
                        
                        try await withThrowingTaskGroup(of: Void.self) {
                            $0.addTask { try await PersistenceManager.shared.progress.sync(sessions: sessions, connectionID: connectionID) }
                            $0.addTask { try await PersistenceManager.shared.bookmark.sync(bookmarks: bookmarks, connectionID: connectionID) }
                            
                            try await $0.waitForAll()
                        }
                        
                        success = true
                    } catch {
                        success = false
                    }
                    
                    try Task.checkCancellation()
                    await callback(success)
                }
            }
    }
}

#Preview {
    SessionImporter(connectionID: "fixture") { _ in
        // Nothing
    }
}
