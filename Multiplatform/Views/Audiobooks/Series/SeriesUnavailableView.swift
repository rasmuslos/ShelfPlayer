//
//  SeriesUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct SeriesUnavailableView: View {
    var body: some View {
        ContentUnavailableView("error.unavailable.series", systemImage: "text.justify.leading", description: Text("error.unavailable.text"))
    }
}

#Preview {
    SeriesUnavailableView()
}
