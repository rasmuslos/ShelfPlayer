//
//  HomeHelper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import Defaults
import ShelfPlayerKit

extension HomeRow {
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
    
    var itemIDs: [ItemIdentifier] {
        entities.map(\.id)
    }
    
    // TODO: Hide from continue listening
    static func prepareForPresentation<S>(_ rows: [HomeRow<S>], connectionID: ItemIdentifier.ConnectionID) async -> [HomeRow<S>] {
        let hideDiscoverRow = Defaults[.hideDiscoverRow]
        let hiddenIDs = await PersistenceManager.shared.progress.hiddenFromContinueListening(connectionID: connectionID)
        
        return rows.compactMap { (row: HomeRow<S>) -> HomeRow<S>? in
            if row.id == "discover" && hideDiscoverRow {
                nil
            } else if row.id != "continue-listening" {
                row
            } else {
                .init(id: row.id, label: row.label, entities: row.entities.filter { !hiddenIDs.contains($0.id.primaryID) })
            }
        }
    }
}
