//
//  AuthorizationStrategy.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 15.08.25.
//

public enum AuthorizationStrategy: Int, Identifiable {
    case usernamePassword
    case openID
    
    public var id: Int {
        rawValue
    }
}
