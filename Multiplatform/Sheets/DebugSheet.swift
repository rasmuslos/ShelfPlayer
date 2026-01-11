//
//  DebugSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.01.26.
//

import SwiftUI
import ShelfPlayback

#if DEBUG
struct DebugSheet: View {
    @State private var general = [String: String]()
    
    @ViewBuilder
    private func row(_ label: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
            Spacer(minLength: 4)
            Text(value)
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(Array(general.keys).sorted(), id: \.hashValue) {
                    row($0, value: general[$0]!)
                }
            }
            
            Button(String("Reconnect sockets")) {
                PersistenceManager.shared.webSocket.reconnect()
            }
        }
        .task {
            general.removeAll()
            
            general["offline"] = OfflineMode.shared.isEnabled.description
            general["socketCount"] = PersistenceManager.shared.webSocket.connected.description
        }
    }
}

#Preview {
    DebugSheet()
}
#else
typealias DebugSheet = EmptyView
#endif
