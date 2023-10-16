//
//  AudiobookshelfClient.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

class AudiobookshelfClient {
    private(set) var serverUrl: URL!
    private(set) var token: String!
    
    private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    private(set) var clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    
    private init(serverUrl: URL!, token: String!) {
        self.serverUrl = serverUrl
        self.token = token
    }
    
    lazy private(set) var isAuthorized = {
        self.token != nil
    }()
}

// MARK: Setter

extension AudiobookshelfClient {
    func setServerUrl(_ serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw AudiobookshelfClientError.invalidServerUrl
        }
        
        UserDefaults.standard.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    func setToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "token")
        self.token = token
    }
    
    func logout() {
        UserDefaults.standard.set(nil, forKey: "token")
        exit(0)
    }
}

// MARK: Singleton

extension AudiobookshelfClient {
    static let shared = {
        AudiobookshelfClient(
            serverUrl: UserDefaults.standard.url(forKey: "serverUrl"),
            token: UserDefaults.standard.string(forKey: "token"))
    }()
}
