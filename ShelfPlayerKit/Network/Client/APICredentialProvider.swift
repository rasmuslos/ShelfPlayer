//
//  APICredentialProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation

public protocol APICredentialProvider: Sendable {
    var configuration: (URL, [HTTPHeader]) { get async throws }
    var accessToken: String? { get async throws }
    
    var shouldPostAuthorizationFailure: Bool { get async }
    
    func refreshAccessToken(current: String?) async throws -> String?
}
