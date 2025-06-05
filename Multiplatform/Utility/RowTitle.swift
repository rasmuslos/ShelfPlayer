//
//  RowTitle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct RowTitle: View {
    @Default(.enableSerifFont) private var enableSerifFont
    
    let title: String
    var fontDesign: Font.Design? = nil
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontDesign(fontDesign == .serif && !enableSerifFont ? nil : fontDesign)
            .accessibilityAddTraits(.isHeader)
            .accessibilityRemoveTraits(.isStaticText)
    }
}

#if DEBUG
#Preview {
    RowTitle(title: "Title")
}

#Preview {
    RowTitle(title: "Title", fontDesign: .serif)
}
#endif
