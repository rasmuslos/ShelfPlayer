//
//  File.swift
//
//
//  Created by Rasmus Krämer on 23.01.24.
//

import Foundation

public extension ShelfPlayerKit {
    static let groupContainer = "group.io.rfk.shelfplayer"
    
    static nonisolated(unsafe) var enableCentralized = true
    
    static let clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    static let clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    static let osVersion: String = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }()
    
    static let model: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let bytes = withUnsafeBytes(of: systemInfo.machine.self) { [UInt8]($0) }
        let firstWhitespaceIndex = bytes.firstIndex(of: 0x00) ?? bytes.endIndex
        
        return String(decoding: bytes[0..<firstWhitespaceIndex], as: UTF8.self)
    }()
    
    static var suite: UserDefaults {
        enableCentralized ? UserDefaults(suiteName: groupContainer)! : UserDefaults.standard
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
        if ShelfPlayerKit.enableCentralized {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainer)!.appending(path: "DownloadV2")
        } else {
            URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "DownloadV2")
        }
    }
}
