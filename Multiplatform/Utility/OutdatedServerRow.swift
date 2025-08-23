//
//  OutdatedServerRow.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.08.25.
//

import SwiftUI

struct OutdatedServerRow: View {
    private let suggestedServerVersion = (2, 26, 0)
    
    let version: String?
    
    var isUsingOutdatedServer: Bool {
        let parts = version?.split(separator: ".").compactMap { Int($0) }
        
        guard let parts, parts.count == 3 else {
            return false
        }
        
        if parts[0] >= suggestedServerVersion.0 {
            return false
        }
        if parts[1] >= suggestedServerVersion.1 {
            return false
        }
        if parts[2] >= suggestedServerVersion.2 {
            return false
        }
        
        return true
    }
    
    var body: some View {
        if isUsingOutdatedServer {
            Text("connection.outdatedServer")
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    List {
        ForEach(["1.1.1", "2.25.4", "2.26.0", "2.28.0", "3.0.0"], id: \.hashValue) { version in
            Section(version) {
                OutdatedServerRow(version: version)
            }
        }
    }
}
