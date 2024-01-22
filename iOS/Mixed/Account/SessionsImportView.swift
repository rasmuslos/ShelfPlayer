//
//  SessionsImportView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import OSLog
import SPBase
import SPOffline

struct SessionsImportView: View {
    let logger = Logger(subsystem: "io.rfk.audiobooks", category: "SessionImport")
    
    var callback: (_ success: Bool) -> ()
    @State var task: Task<(), Error>?
    
    var body: some View {
        ProgressView {
            Button {
                task?.cancel()
                callback(false)
            } label: {
                Label("offline.enable", systemImage: "network.slash")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
        }
        .onAppear {
            task = Task.detached {
                let success = await OfflineManager.shared.syncProgressEntities()
                callback(success)
            }
        }
    }
}

#Preview {
    SessionsImportView() { success in
        print("import finished", success)
    }
}
