//
//  VocabularyDonator.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import Foundation
import Intents
import SPBaseKit

struct VocabularyDonator {
    static func donateVocabulary() {
        // this does not work because fuck you
        #if false
        Task.detached {
            let libraries = try await AudiobookshelfClient.shared.getLibraries().filter { $0.type == .audiobooks }
            var audiobooks = [Audiobook]()
            
            for library in libraries {
                audiobooks.append(contentsOf: try await AudiobookshelfClient.shared.getAudiobooks(libraryId: library.id))
            }
            
            INVocabulary.shared().setVocabulary(NSOrderedSet(array: audiobooks.map { $0.name }), of: .mediaAudiobookTitle)
            INVocabulary.shared().setVocabulary(NSOrderedSet(array: audiobooks.map { $0.author }.filter { $0 != nil } as! [String]), of: .mediaAudiobookAuthorName)
        }
        #endif
    }
}
