//
//  SeriesUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct SeriesUnavailableView: View {
    var body: some View {
        ContentUnavailableView("Series unavailable", systemImage: "text.justify.leading", description: Text("Please ensure that you are connected to the internet"))
    }
}

#Preview {
    SeriesUnavailableView()
}
