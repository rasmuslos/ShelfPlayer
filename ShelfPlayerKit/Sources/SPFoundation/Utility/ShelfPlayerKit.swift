//
//  File.swift
//
//
//  Created by Rasmus Krämer on 23.01.24.
//

import Foundation
import OSLog

#if canImport(UIKit)
import UIKit
#endif

public struct ShelfPlayerKit {
    public static let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ShelfPlayerKit")
}

public extension ShelfPlayerKit {
    static let groupContainer = "group.io.rfk.shelfplayer"
    
    static nonisolated(unsafe) var enableCentralized = true
    
    static let clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    static let clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    #if canImport(UIKit)
    @MainActor
    static let osVersion = UIDevice.current.systemVersion
    #endif
    
    static let model: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        return String(decoding: withUnsafeBytes(of: systemInfo.machine.self) { [UInt8]($0) }, as: UTF8.self)
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
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.rfk.shelfplayer")!.appending(path: "DownloadV2")
        } else {
            URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "DownloadV2")
        }
    }
}
