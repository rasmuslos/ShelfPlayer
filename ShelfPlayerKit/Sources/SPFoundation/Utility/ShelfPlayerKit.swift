//
//  File.swift
//
//
//  Created by Rasmus Krämer on 23.01.24.
//

import Foundation

public struct ShelfPlayerKit {
    
}

public extension ShelfPlayerKit {
    static let groupContainer = "group.io.rfk.shelfplayer"
    
    static nonisolated(unsafe) var enableCentralized = true
    
    static let clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    static let clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    static let machine: String = {
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
}
