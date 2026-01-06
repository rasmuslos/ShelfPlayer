//
//  CustomTabValueSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import ShelfPlayback

struct CustomTabValueSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Default(.pinnedTabValues) private var pinnedTabValues
    
    var body: some View {
        NavigationStack {
            CustomTabValuesPreferences()
                .toolbar {
                    Button("action.dismiss") {
                        dismiss()
                    }
                }
        }
        .onDisappear {
            if !pinnedTabValues.isEmpty {
                RFNotification[.enablePinnedTabs].send()
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
