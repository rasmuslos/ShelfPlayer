//
//  AudiobookSection.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.11.24.
//

import Foundation
import ShelfPlayerKit

internal enum AudiobookSection: Hashable {
    case audiobook(audiobook: Audiobook)
    case series(seriesName: String, audiobooks: [Audiobook])
    
    var sortName: String {
        switch self {
        case .audiobook(let audiobook):
            return audiobook.sortName
        case .series(let seriesName, _):
            var sortName = seriesName.lowercased()
            
            if sortName.starts(with: "a ") {
                sortName = String(sortName.dropFirst(2))
            }
            if sortName.starts(with: "the ") {
                sortName = String(sortName.dropFirst(4))
            }
            
            return sortName
        }
    }
    var seriesName: String? {
        switch self {
        case .audiobook(let audiobook):
            audiobook.seriesName
        case .series(let seriesName, _):
            seriesName
        }
    }
    var authorName: String? {
        switch self {
        case .audiobook(let audiobook):
            audiobook.authors.formatted(.list(type: .and, width: .short))
        case .series(_, let audiobooks):
            Dictionary(audiobooks.map { ($0.authors.formatted(.list(type: .and, width: .short)), 1) }, uniquingKeysWith: +).sorted { $0.value < $1.value }.compactMap(\.key).first
        }
    }
    var released: String? {
        switch self {
        case .audiobook(let audiobook):
            audiobook.released
        case .series(_, let audiobooks):
            audiobooks.first?.released
        }
    }
    var added: Date? {
        switch self {
        case .audiobook(let audiobook):
            audiobook.addedAt
        case .series(_, let audiobooks):
            audiobooks.first?.addedAt
        }
    }
    var duration: TimeInterval {
        switch self {
        case .audiobook(let audiobook):
            audiobook.duration
        case .series(_, let audiobooks):
            audiobooks.reduce(0, { $0 + $1.duration })
        }
    }
}

internal extension AudiobookSection {
    static func group(_ audiobooks: [Audiobook]) -> [AudiobookSection] {
        let grouped = Dictionary(audiobooks.map { ($0.series.first?.name, [$0]) }, uniquingKeysWith: +)
        
        return grouped.flatMap { seriesName, audiobooks in
            if audiobooks.count > 1, let seriesName {
                return [AudiobookSection.series(seriesName: seriesName, audiobooks: audiobooks)]
            } else {
                return audiobooks.map { .audiobook(audiobook: $0) }
            }
        }
    }
    
    static func filterSortGroup(_ audiobooks: [Audiobook], filter: ItemFilter, sortOrder: AudiobookSortOrder, ascending: Bool) -> [AudiobookSection] {
        let sections = group(Audiobook.filter(audiobooks, filter: filter)).sorted {
            if case .audiobook(let lhs) = $0, case .audiobook(let rhs) = $1 {
                return Audiobook.compare(lhs, rhs, sortOrder)
            }
            
            switch sortOrder {
            case .sortName:
                return $0.sortName < $1.sortName
            case .seriesName:
                guard let lhsSeriesName = $0.seriesName else {
                    return false
                }
                guard let rhsSeriesName = $1.seriesName else {
                    return true
                }
                
                return lhsSeriesName < rhsSeriesName
            case .authorName:
                guard let lhsAuthorName = $0.authorName else {
                    return false
                }
                guard let rhsAuthorName = $1.authorName else {
                    return true
                }
                
                return lhsAuthorName < rhsAuthorName
            case .released:
                guard let lhsReleased = $0.released else {
                    return false
                }
                guard let rhsReleased = $1.released else {
                    return true
                }
                
                return lhsReleased < rhsReleased
            case .added:
                guard let lhsAdded = $0.added else {
                    return false
                }
                guard let rhsAdded = $1.added else {
                    return true
                }
                
                return lhsAdded < rhsAdded
            case .duration:
                return $0.duration < $1.duration
            case .lastPlayed:
                fatalError("Not implemented")
            }
        }
        
        if ascending {
            return sections
        } else {
            return sections.reversed()
        }
    }
}

extension AudiobookSection: Identifiable {
    public var id: Int {
        self.hashValue
    }
}
