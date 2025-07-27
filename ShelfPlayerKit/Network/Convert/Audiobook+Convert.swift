//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension Audiobook {
    convenience init?(payload: ItemPayload, libraryID: ItemIdentifier.LibraryID?, connectionID: ItemIdentifier.ConnectionID) {
        guard let media = payload.media else {
            return nil
        }
        
        // This filters out e-books but gives items the benefit of the doubt
        guard media.numAudioFiles ?? media.audioFiles?.count ?? 1 > 0 else {
            return nil
        }
        
        var resolvedSeries = [SeriesFragment]()
        
        if let series = payload.media?.metadata.series, !series.isEmpty {
            resolvedSeries += series.map {
                let name = $0.name!
                let id: ItemIdentifier?
                
                if let seriesID = $0.id {
                    id = .init(primaryID: seriesID, groupingID: nil, libraryID: libraryID ?? payload.libraryId!, connectionID: connectionID, type: .series)
                } else {
                    id = nil
                }
                
                if let seq = $0.sequence, let sequence = Float(seq) {
                    return Audiobook.SeriesFragment(id: id, name: name, sequence: sequence)
                } else {
                    return Audiobook.SeriesFragment(id: id, name: name, sequence: nil)
                }
            }
        }
        
        if let seriesName = payload.media?.metadata.seriesName {
            let series = SeriesFragment.parse(seriesName: seriesName)
            
            for series in series {
                if !resolvedSeries.contains(where: { $0.name == series.name }) {
                    resolvedSeries.append(series)
                }
            }
        }
        
        let addedAt = payload.addedAt ?? 0
        let duration = media.duration ?? 0
        
        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: payload.libraryId!, connectionID: connectionID, type: .audiobook),
            name: media.metadata.title!,
            authors: media.metadata.authorName?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: media.metadata.description?.trimmingCharacters(in: .whitespacesAndNewlines),
            genres: media.metadata.genres,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: media.metadata.publishedYear,
            size: payload.size,
            duration: duration,
            subtitle: media.metadata.subtitle,
            narrators: media.metadata.narratorName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: ", ")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [],
            series: resolvedSeries,
            explicit: payload.media?.metadata.explicit ?? false,
            abridged: payload.media?.metadata.abridged ?? false)
    }
}
