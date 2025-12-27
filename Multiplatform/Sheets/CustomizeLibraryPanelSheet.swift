//
//  CustomizeLibraryPanelSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 24.12.25.
//

import SwiftUI
import ShelfPlayback

struct CustomizeLibraryPanelSheet: View {
    @Environment(Satellite.self) private var satellite
    
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope
    
    var body: some View {
        NavigationStack {
            TabValueLibraryPreferences(library: library, scope: scope) {
                satellite.dismissSheet()
            }
            .toolbarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            CustomizeLibraryPanelSheet(library: .fixture, scope: .tabBar)
        }
        .previewEnvironment()
}
#endif
