//
//  AudiobookshelfClient+Request.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

extension AudiobookshelfClient {
    struct ClientRequest<T> {
        var path: String
        var method: String
        var body: Any?
        var query: [URLQueryItem]?
    }
    
    struct EmptyResponse: Decodable {}
    
    func request<T: Decodable>(_ clientRequest: ClientRequest<T>) async throws -> T {
        var url = serverUrl.appending(path: clientRequest.path)
        
        if let query = clientRequest.query {
            url = url.appending(queryItems: query)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = clientRequest.method
        request.httpShouldHandleCookies = true
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        for pair in customHTTPHeaders {
            request.addValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        if let body = clientRequest.body {
            do {
                if let encodable = body as? Encodable {
                    let encoder = JSONEncoder()
                    request.httpBody = try encoder.encode(encodable)
                } else {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                }
                
                // print(clientRequest.path, clientRequest.method, String(data: request.httpBody!, encoding: .ascii))
                
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                print("Unable to encode body \(error)")
                throw AudiobookshelfClientError.invalidHttpBody
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
            print(url, error)
            throw AudiobookshelfClientError.invalidResponse
        }
    }
}
