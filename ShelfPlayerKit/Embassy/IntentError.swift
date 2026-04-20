//
//  IntentError.swift
//  ShelfPlayerKit
//

import Foundation

public enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case notFound

    case noPlaybackItem
    case invalidItemType

    case wrongExecutionContext

    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound:
            "intent.error.notFound"
        case .noPlaybackItem:
            "intent.error.noPlaybackItem"
        case .invalidItemType:
            "intent.error.invalidItemType"
        default:
            "intent.error"
        }
    }
}
