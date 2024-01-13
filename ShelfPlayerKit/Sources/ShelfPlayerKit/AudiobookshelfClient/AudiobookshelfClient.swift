//
//  AudiobookshelfClient.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

public class AudiobookshelfClient {
    public private(set) var serverUrl: URL!
    public private(set) var token: String!
    
    public private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    public private(set) var clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    
    #if DISABLE_APP_GROUP
    #warning("UserDefaults will not be stored in group container")
    static let defaults = UserDefaults.standard
    #else
    static let defaults = UserDefaults(suiteName: "group.io.rfk.shelfplayer")!
    #endif
    
    private init(serverUrl: URL!, token: String!) {
        self.serverUrl = serverUrl
        self.token = token
    }
    
    lazy public private(set) var isAuthorized = {
        self.token != nil
    }()
}

// MARK: Setter

extension AudiobookshelfClient {
    public func setServerUrl(_ serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw AudiobookshelfClientError.invalidServerUrl
        }
        
        Self.defaults.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    public func setToken(_ token: String) {
        Self.defaults.set(token, forKey: "token")
        self.token = token
    }
    
    public func logout() {
        Self.defaults.set(nil, forKey: "token")
        exit(0)
    }
}

// MARK: Singleton

extension AudiobookshelfClient {
    public static let shared = {
        AudiobookshelfClient(
            serverUrl: defaults.url(forKey: "serverUrl"),
            token: defaults.string(forKey: "token"))
    }()
}
