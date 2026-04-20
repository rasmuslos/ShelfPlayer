//
//  URL+AllocatedSize.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 09.11.24.
//

import Foundation

extension URL {
    nonisolated func directoryTotalAllocatedSize(recursive: Bool = true) throws -> Int? {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true, try checkResourceIsReachable() else {
            return nil
        }

        let contents: [URL]

        if recursive, let objects = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] {
            contents = objects
        } else {
            contents = try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
        }

        return contents.lazy.reduce(0) {
            $0 + ((try? $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
        }
    }
}
