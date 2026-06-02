//
//  CustomTabValueSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import ShelfPlayback

struct CustomTabValueSheet: View {
    var body: some View {
        NavigationStack {
            CustomTabValuesPreferences()
        }
        .onDisappear {
            if !AppSettings.shared.pinnedTabValues.isEmpty {
                TabEventSource.shared.enablePinnedTabs.send()
            }
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":9")
        .sheet(isPresented: .constant(true)) {
            CustomTabValueSheet()
                .previewEnvironment()
        }
}
#endif
