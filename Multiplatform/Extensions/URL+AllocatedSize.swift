//
//  URL+Size.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.11.24.
//

import Foundation

extension URL {
    func directoryTotalAllocatedSize(recursive: Bool = true) throws -> Int? {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true, try checkResourceIsReachable() else {
            return nil
        }
        
        let contents: [URL]
        
        if recursive, let objects = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] {
            contents = objects
        } else {
            contents = try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
        }
        
        return try contents.lazy.reduce(0) {
            let size = try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize
            
            guard let size else {
                return $0
            }
            
            return $0 + size
        }
    }
}
