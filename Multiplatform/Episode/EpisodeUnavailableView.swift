//
//  EpisodeUnavailableView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

struct EpisodeUnavailableView: View {
    var body: some View {
        ContentUnavailableView("error.unavailable.episode", systemImage: "waveform", description: Text("error.unavailable.text"))
    }
}

#Preview {
    AudiobookUnavailableView()
}
