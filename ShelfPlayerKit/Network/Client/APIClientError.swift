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
                description = "APIClientError | Invalid response code \(code)"
            case .offline:
                description = "APIClientError | Offline"
            case .notFound:
                description = "APIClientError | Not Found"
            case .cancelled:
                description = "APIClientError | Cancelled"
            case .unauthorized:
                description = "APIClientError | Unauthorized"
            case .noAttemptsLeft:
                description = "APIClientError | No attempts left"
            default:
                return nil
        }
        
        return "The operation could not be completed: \(description)"
    }
}
