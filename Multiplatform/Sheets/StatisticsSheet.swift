//
//  StatisticsSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.05.25.
//

import SwiftUI
import ShelfPlayerKit

#if DEBUG
struct StatisticsSheet: View {
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    var body: some View {
        List {
            
        }
    }
}
#endif

#if DEBUG
#Preview {
    StatisticsSheet()
        .previewEnvironment()
}
#endif
