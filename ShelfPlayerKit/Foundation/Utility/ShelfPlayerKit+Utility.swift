//
//  File.swift
//
//
//  Created by Rasmus Krämer on 23.01.24.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public extension ShelfPlayerKit {
    static let groupContainer = "group.io.rfk.shelfplayer"
    
    #if ENABLE_CENTRALIZED
    static nonisolated(unsafe) var enableCentralized = true
    #else
    static nonisolated(unsafe) var enableCentralized = false
    #endif
    
    static let clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    static let clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    #if canImport(UIKit)
    @MainActor
    static let osVersion = UIDevice.current.systemVersion
    #endif
    
    static let model: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let bytes = withUnsafeBytes(of: systemInfo.machine.self) { [UInt8]($0) }
        let firstWhitespaceIndex = bytes.firstIndex(of: 0x00) ?? bytes.endIndex
        
        return String(decoding: bytes[0..<firstWhitespaceIndex], as: UTF8.self)
    }()
    
    static var suite: UserDefaults {
        enableCentralized ? UserDefaults(suiteName: groupContainer)! : .standard
    }
    
    private static nonisolated(unsafe) var _clientID: String? = nil
    static var clientID: String {
        if let clientID = suite.string(forKey: "clientId") {
            _clientID = clientID
        } else {
            _clientID = String(length: 100)
            suite.set(_clientID, forKey: "clientId")
        }
        
        return _clientID!
    }
    
    static var downloadDirectoryURL: URL {
        if enableCentralized {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainer)!.appending(path: "DownloadV2")
        } else {
            URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "DownloadV2")
        }
    }
    static var cacheDirectoryURL: URL {
        var url: URL
        
        if enableCentralized {
            url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainer)!.appending(path: "Cache")
        } else {
            url = URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "Cache")
        }
        
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        
        do {
            try url.setResourceValues(resourceValues)
            try (url as NSURL).setResourceValue(URLFileProtection.completeUntilFirstUserAuthentication, forKey: .fileProtectionKey)
        } catch {
            logger.error("Failed to set URL as encrypted or excluded from backup: \(error)")
        }
        
        return url
    }
    
    static var httpCookieStorage: HTTPCookieStorage {
        if enableCentralized {
            .sharedCookieStorage(forGroupContainerIdentifier: groupContainer)
        } else {
            .shared
        }
    }
}

public extension ShelfPlayerKit {
    static let suggestedServerVersion = (2, 26, 0)
    static func isUsingOutdatedServer(_ version: String?) -> Bool {
        guard let version = version, let parts = version.split(separator: ".").compactMap({ Int($0) }) as [Int]?, parts.count == 3 else {
            return false
        }
        
        let currentVersion = (parts[0], parts[1], parts[2])
        return currentVersion < suggestedServerVersion
    }
    
    static let currentToSVersion = 1
}
