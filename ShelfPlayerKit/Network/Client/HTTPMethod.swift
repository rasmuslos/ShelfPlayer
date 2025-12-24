//
//  HTTPMethod.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation

public enum HTTPMethod: Sendable {
        case get
        case post
        case patch
        case delete
        
        var value: String {
            switch self {
            case .get:
                "GET"
            case .post:
                "POST"
            case .patch:
                "PATCH"
            case .delete:
                "DELETE"
            }
        }
    }
