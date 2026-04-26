//
//  APIRequestProtocol.swift
//  ShelfPlayerKit
//

import Foundation

public protocol APIRequestProtocol: Identifiable, Hashable, Sendable, Equatable {
    associatedtype Response: Decodable & Sendable

    var id: String { get }

    var path: String { get }
    var method: HTTPMethod { get }

    var body: Any? { get }
    var query: [URLQueryItem] { get }
    var headers: [String: String] { get }

    var ttl: TimeInterval? { get }
    var timeout: TimeInterval { get }
    var maxAttempts: Int { get }
    var bypassesOffline: Bool { get }
    var bypassesScheduler: Bool { get }
    var bypassesCache: Bool { get }

    func _typecast(_ data: Data) throws -> Response
    func typecast(decodable: Decodable) throws -> Response

    var description: String { get }
}

public extension APIRequestProtocol {
    func typecast(data: Data) throws -> Response {
        switch Response.self {
        case is APIClient.DataResponse.Type: APIClient.DataResponse(data: data) as! Response
        case is APIClient.EmptyResponse.Type: APIClient.EmptyResponse() as! Response
        default: try _typecast(data)
        }
    }
}
