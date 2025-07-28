//
//  APICredentialProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation

public protocol APICredentialProvider: Sendable {
    var configuration: (URL, [HTTPHeader], SecIdentity?) { get async throws }
    func requestSessionToken(refresh: Bool) async throws -> String?
}
