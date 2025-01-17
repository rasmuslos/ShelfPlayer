//
//  EpisodeUnavailableView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

struct EpisodeUnavailableView: View {
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("error.unavailable.episode", systemImage: "play.square.stack", description: Text("error.unavailable.text"))
        }
    }
}

#Preview {
    EpisodeUnavailableView()
}
