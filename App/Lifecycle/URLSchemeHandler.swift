//
//  URLSchemeHandler.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.26.
//

import Foundation
import OSLog
import ShelfPlayback

@MainActor
enum URLSchemeHandler {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "URLSchemeHandler")

    @discardableResult
    static func handle(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "shelfplayer" else {
            return false
        }

        guard let host = url.host(percentEncoded: false)?.lowercased() else {
            return true
        }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        func value(_ keys: String...) -> String? {
            for key in keys {
                if let value = queryItems.first(where: { $0.name == key })?.value {
                    return value
                }
            }
            return nil
        }

        func itemID(_ keys: String...) -> ItemIdentifier? {
            for key in keys {
                if let value = queryItems.first(where: { $0.name == key })?.value, ItemIdentifier.isValid(value) {
                    return ItemIdentifier(value)
                }
            }
            return nil
        }

        let satellite = Satellite.shared

        switch host {
            case "open":
                if let itemID = itemID("item", "id") {
                    navigate(to: itemID)
                }
            case "item":
                guard let itemID = itemID("id", "item") else {
                    logger.warning("URL 'item' action missing valid item identifier: \(url, privacy: .public)")
                    return false
                }
                navigate(to: itemID)
            case "play":
                if let itemID = itemID("item", "id") {
                    let at = value("at").flatMap(TimeInterval.init)
                    satellite.start(itemID, at: at)
                } else {
                    satellite.play()
                }
            case "pause":
                satellite.pause()
            case "toggle":
                satellite.togglePlaying()
            case "stop":
                satellite.stop()
            case "skip":
                let direction = value("direction")?.lowercased()
                satellite.skip(forwards: direction != "backward" && direction != "back")
            case "seek":
                guard let time = value("to").flatMap(TimeInterval.init) else {
                    logger.warning("URL 'seek' action missing 'to' query parameter: \(url, privacy: .public)")
                    return false
                }
                satellite.seek(to: time, insideChapter: false, completion: {})
            case "bookmark":
                PlaybackViewModel.shared.createQuickBookmark()
            case "search":
                let query = value("q", "query") ?? ""
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    NavigationEventSource.shared.setGlobalSearch.send((query, .global))
                }
            default:
                logger.warning("Unknown URL scheme action '\(host, privacy: .public)': \(url, privacy: .public)")
                return false
        }

        return true
    }

    private static func navigate(to itemID: ItemIdentifier) {
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            NavigationEventSource.shared.navigate.send(itemID)
        }
    }
}
