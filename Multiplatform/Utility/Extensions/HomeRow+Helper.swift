//
//  HomeHelper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import Defaults
import ShelfPlayerKit

internal extension HomeRow {
    var localizedLabel: String {
        switch id {
        case "continue-listening":
            String(localized: "row.continueListening")
        case "continue-reading":
            String(localized: "row.continueReading")
        case "continue-series":
            String(localized: "row.continueSeries")
        case "newest-episodes":
            String(localized: "row.latestEpisodes")
        case "recently-added":
            String(localized: "row.recentlyAdded")
        case "recent-series":
            String(localized: "row.recentSeries")
        case "listen-again":
            String(localized: "row.listenAgain")
        case "read-again":
            String(localized: "row.readAgain")
        case "discover":
            String(localized: "row.discover")
        case "newest-authors":
            String(localized: "row.newestAuthors")
        default:
            label
        }
    }
    
    static func prepareForPresentation<S>(_ rows: [HomeRow<S>]) -> [HomeRow<S>] {
        let disableDiscoverRow = Defaults[.disableDiscoverRow]
        // let hideFromContinueListening = Defaults[.hideFromContinueListening]
        
        return rows.compactMap { (row: HomeRow<S>) -> HomeRow<S>? in
            if row.id == "discover" && disableDiscoverRow {
                return nil
            }
            
            guard row.id == "continue-listening" else {
                return row
            }
            
            return .init(id: row.id, label: row.label, entities: row.entities.filter { item in
                // !hideFromContinueListening.contains { $0.itemId == item.identifiers.itemID && $0.episodeId == item.identifiers.episodeID }
                true
            })
        }
    }
}
