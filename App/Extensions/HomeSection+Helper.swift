//
//  HomeSection+Helper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import Foundation
import SwiftUI
import ShelfPlayback

// MARK: - Environment

private struct HomeScopeKey: EnvironmentKey {
    static let defaultValue: HomeScope? = nil
}

extension EnvironmentValues {
    /// Overrides the home scope that a home panel would otherwise derive from
    /// the current library. Set this for pinned-tab contexts so the panel
    /// renders using the pinned-tab's saved customization.
    var homeScope: HomeScope? {
        get { self[HomeScopeKey.self] }
        set { self[HomeScopeKey.self] = newValue }
    }
}

extension HomeSectionKind {
    /// Localized title used when the section has no server-provided label to
    /// fall back to.
    var defaultLocalizedTitle: String {
        switch self {
        case .serverRow(let id):
            Self.localizedServerRowLabel(forID: id) ?? id
        case .listenNow:
            String(localized: "home.section.listenNow")
        case .upNext:
            String(localized: "home.section.upNext")
        case .nextUpPodcasts:
            String(localized: "home.section.nextUpPodcasts")
        case .downloadedAudiobooks:
            String(localized: "home.section.downloadedAudiobooks")
        case .downloadedEpisodes:
            String(localized: "home.section.downloadedEpisodes")
        case .bookmarks:
            String(localized: "home.section.bookmarks")
        }
    }

    var systemImage: String {
        switch self {
        case .serverRow(let id):
            switch id {
            case "continue-listening":
                "play.circle.fill"
            case "continue-reading":
                "book.circle.fill"
            case "continue-series":
                "square.stack.fill"
            case "recent-series":
                "rectangle.stack.fill"
            case "recently-added":
                "sparkles"
            case "listen-again", "read-again":
                "arrow.counterclockwise.circle.fill"
            case "discover":
                "star.fill"
            case "newest-authors":
                "person.2.fill"
            case "newest-episodes":
                "antenna.radiowaves.left.and.right"
            default:
                "square.grid.2x2"
            }
        case .listenNow:
            "headphones"
        case .upNext:
            "text.line.first.and.arrowtriangle.forward"
        case .nextUpPodcasts:
            "forward.end.fill"
        case .downloadedAudiobooks, .downloadedEpisodes:
            "arrow.down.circle.fill"
        case .bookmarks:
            "bookmark.fill"
        }
    }

    /// Local copy of the server-row id → label mapping so that the settings UI
    /// can label sections before remote data is available.
    private static func localizedServerRowLabel(forID id: String) -> String? {
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
            nil
        }
    }
}
