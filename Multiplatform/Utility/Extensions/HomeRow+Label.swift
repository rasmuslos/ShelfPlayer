//
//  HomeRow+Label.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.10.24.
//

import Foundation
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
}
