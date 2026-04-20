//
//  BookmarkEditor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
final class BookmarkEditor {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "BookmarkEditor")

    var isUpdating = false

    var data: (at: UInt64, itemID: ItemIdentifier)?
    var note = ""

    var isPresented: Bool {
        data != nil
    }

    func begin(at time: UInt64, from itemID: ItemIdentifier) {
        Task {
            guard let note = try? await PersistenceManager.shared.bookmark.note(at: time, for: itemID) else {
                return
            }

            data = (time, itemID)
            self.note = note
        }
    }

    func abort() {
        data = nil
        note = ""
        isUpdating = false
    }

    func finalize() {
        Task {
            guard let (time, itemID) = data else {
                return
            }

            isUpdating = true

            do {
                try await PersistenceManager.shared.bookmark.update(at: time, for: itemID, note: note)
            } catch {
                logger.warning("Failed to update bookmark at \(time, privacy: .public) for \(itemID, privacy: .public): \(error, privacy: .public)")
            }

            abort()
        }
    }
}
