//
//  IntentError.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation

public enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noPlaybackItem
    case wrongExecutionContext
    
    public var localizedStringResource: LocalizedStringResource {
        switch self {
            case .noPlaybackItem:
                "intent.error.noPlaybackItem"
            default:
                "intent.error"
        }
    }
}
