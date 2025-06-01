//
//  IntentError.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
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
