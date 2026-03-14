//
//  APIClientError.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation

public enum APIClientError: Error {
    case parseError
    case serializeError
    
    case invalidItemType
    case invalidResponseCode(Int)
    
    // MARK: New
    
    case offline
    case notFound
    case cancelled
    
    case unauthorized
    case noAttemptsLeft
}

extension APIClientError: LocalizedError {
    public var errorDescription: String? {
        let description: String
        
        switch self {
            case .invalidResponseCode(let code):
                description = "Invalid response code '\(code)'"
            case .offline:
                description = "Offline"
            case .notFound:
                description = "Not Found"
            case .cancelled:
                description = "Cancelled"
            case .unauthorized:
                description = "Unauthorized"
            case .noAttemptsLeft:
                description = "Maximum amount of attempts exceeded"
            default:
                description = "Unexpected error. Please open an issue on GitHub and include the debug logs."
        }
        
        return "The networking-operation could not be completed: \(description)"
    }
}
