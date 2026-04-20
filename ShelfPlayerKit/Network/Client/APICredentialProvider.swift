//
//  APICredentialProvider.swift
//  ShelfPlayerKit
//

import Foundation

public protocol APICredentialProvider: Sendable {
    var configuration: (URL, [HTTPHeader]) { get async throws }

    var accessToken: String? { get async throws }
    func refreshAccessToken() async throws
}
