//
//  DebugSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.01.26.
//

import SwiftUI
import ShelfPlayback

#if DEBUG
struct DebugSheet: View {
    @State private var general = [String: String]()

    var body: some View {
        List {
            Section {
                ForEach(Array(general.keys).sorted(), id: \.self) {
                    LabeledContent($0, value: general[$0]!)
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
