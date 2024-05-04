//
//  RowTitle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults

struct RowTitle: View {
    @Default(.useSerifFont) private var useSerifFont
    
    let title: String
    var fontDesign: Font.Design? = nil
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontDesign(fontDesign == .serif && !useSerifFont ? nil : fontDesign)
            .padding(.top, 10)
    }
}

#Preview {
    RowTitle(title: "Title")
}

#Preview {
    RowTitle(title: "Title", fontDesign: .serif)
}
