//
//  SessionsImportView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct SessionsImportView: View {
    var callback: () -> ()
    
    @State var failed = false
    
    var body: some View {
        if !failed {
            LoadingView()
                .task {
                    if let sessions = try? await AudiobookshelfClient.shared.authorize() {
                        await OfflineManager.shared.importSessions(sessions)
                        callback()
                    }
                }
        } else {
            ErrorView()
        }
    }
}

#Preview {
    SessionsImportView() {
        print("import finished")
    }
}
