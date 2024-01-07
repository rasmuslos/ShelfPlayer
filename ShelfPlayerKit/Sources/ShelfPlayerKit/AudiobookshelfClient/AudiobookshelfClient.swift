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
    
    static let defaults = UserDefaults(suiteName: AudiobookshelfClient.groupIdentifier)!
    
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

extension AudiobookshelfClient {
    static var groupIdentifier: String {
        let fallback = "group.io.rfk.shelfplayer"
        let queryLoad: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "bundleSeedLookup" as AnyObject,
            kSecAttrService as String: "ShelfPlayer" as AnyObject,
            kSecReturnAttributes as String: kCFBooleanTrue,
        ]
        
        var result: AnyObject?
        var status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(to: &result) {
                SecItemAdd(queryLoad as CFDictionary, UnsafeMutablePointer($0))
            }
        }
        
        if status == noErr,
           let resultDict = result as? [String: Any], let accessGroup = resultDict[kSecAttrAccessGroup as String] as? String,
           let seedID = accessGroup.components(separatedBy: ".").first,
           seedID != "N8AA4S3S96" {
            return "\(fallback).\(seedID)"
        }
        
        return fallback
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
