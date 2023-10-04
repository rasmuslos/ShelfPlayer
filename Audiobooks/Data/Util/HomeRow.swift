//
//  HomeRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

struct AudiobookHomeRow: Identifiable {
    let id: String
    let label: String
    let audiobooks: [Audiobook]
}

struct AuthorHomeRow: Identifiable {
    let id: String
    let label: String
    let authors: [Int]
}

