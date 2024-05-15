//
//  AudiobookshelfClient.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import SwiftUI

@Observable
public final class AudiobookshelfClient {
    public private(set) var serverUrl: URL!
    public private(set) var _token: String?
    
    public private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    public private(set) var clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    
    public private(set) var clientId: String
    
    public static let defaults = ENABLE_ALL_FEATURES ? UserDefaults(suiteName: "group.io.rfk.shelfplayer")! : UserDefaults.standard
    
    fileprivate var _customHTTPHeaders: [CustomHTTPHeader]?
    
    init(serverUrl: URL!, token: String!) {
        if !ENABLE_ALL_FEATURES {
            print("[WARNING] User data will not be stored in an app group")
        }
        
        _serverUrl = serverUrl
        _token = token
        
        if let clientId = Self.defaults.string(forKey: "clientId") {
            self.clientId = clientId
        } else {
            clientId = String.random(length: 100)
            Self.defaults.set(clientId, forKey: "clientId")
        }
    }
}

public extension AudiobookshelfClient {
    var authorized: Bool {
        _token != nil
    }
    var token: String {
        _token ?? ""
    }
    
    func store(serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw AudiobookshelfClientError.invalidServerUrl
        }
        
        Self.defaults.set(serverUrl, forKey: "serverUrl")
        _serverUrl = serverUrl
    }
    
    func store(token: String?) {
        Self.defaults.set(token, forKey: "token")
        _token = token
    }
    
    func logout() {
        store(token: nil)
    }
}

public extension AudiobookshelfClient {
    var customHTTPHeaders: [CustomHTTPHeader] {
        get {
            if let customHTTPHeaders = _customHTTPHeaders {
                return customHTTPHeaders
            }
            
            let decoder = JSONDecoder()
            if
                let object = Self.defaults.object(forKey: "customHTTPHeaders") as? Data,
                let headers = try? decoder.decode([CustomHTTPHeader].self, from: object) {
                _customHTTPHeaders = headers
                return headers
            }
            
            return []
        }
        set {
            _customHTTPHeaders = newValue
            
            let encoder = JSONEncoder()
            if let object = try? encoder.encode(newValue) {
                Self.defaults.set(object, forKey: "customHTTPHeaders")
            }
        }
    }
    
    struct CustomHTTPHeader: Codable {
        public var key: String
        public var value: String
        
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
}

enum AudiobookshelfClientError: Error {
    case invalidServerUrl
    case invalidHttpBody
    case invalidResponse
    case missing
}

extension AudiobookshelfClient {
    public static let shared = AudiobookshelfClient(serverUrl: defaults.url(forKey: "serverUrl"), token: defaults.string(forKey: "token"))
}
