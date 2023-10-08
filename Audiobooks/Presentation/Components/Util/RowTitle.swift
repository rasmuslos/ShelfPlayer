//
//  RowTitle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct RowTitle: View {
    let title: String
    var fontDesign: Font.Design? = nil
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontDesign(fontDesign)
            .padding(.horizontal)
            .padding(.bottom, 0)
            .padding(.top, 10)
    }
}

#Preview {
    RowTitle(title: "Title")
}
