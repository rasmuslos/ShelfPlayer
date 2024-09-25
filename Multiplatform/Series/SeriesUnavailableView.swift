//
//  SeriesUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

internal struct SeriesUnavailableView: View {
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("error.unavailable.series", systemImage: "rectangle.grid.2x2.fill", description: Text("error.unavailable.text"))
        }
    }
}

#Preview {
    SeriesUnavailableView()
}
