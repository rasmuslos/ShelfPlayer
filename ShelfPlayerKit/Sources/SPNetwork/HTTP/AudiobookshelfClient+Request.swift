//
//  AudiobookshelfClient+Request.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
 
internal extension AudiobookshelfClient {
    func request<T: Decodable>(_ clientRequest: ClientRequest<T>) async throws -> T {
        var url = serverUrl.appending(path: clientRequest.path)
        
        if let query = clientRequest.query {
            url = url.appending(queryItems: query)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = clientRequest.method
        request.httpShouldHandleCookies = true
        
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        for pair in customHTTPHeaders {
            request.addValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        if let body = clientRequest.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                if let encodable = body as? Encodable {
                    let encoder = JSONEncoder()
                    request.httpBody = try encoder.encode(encodable)
                } else {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                }
                
                // print(clientRequest.path, clientRequest.method, String(data: request.httpBody!, encoding: .ascii))
            } catch {
                logger.fault("Unable to encode body \(error)")
                throw ClientError.invalidHttpBody
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // print(clientRequest.path, clientRequest.method, String.init(data: data, encoding: .utf8))
            
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.fault("Failed to parse \(url): \(error)")
            throw ClientError.invalidResponse
        }
    }
}

internal extension AudiobookshelfClient {
    struct ClientRequest<T> {
        var path: String
        var method: String
        var body: Any?
        var query: [URLQueryItem]?
    }
    
    struct EmptyResponse: Decodable {}
}
