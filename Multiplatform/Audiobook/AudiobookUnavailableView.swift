//
//  AudiobookUnavailableView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

internal struct AudiobookUnavailableView: View {
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("error.unavailable.audiobook", systemImage: "book", description: Text("error.unavailable.text"))
        }
    }
}

#Preview {
    AudiobookUnavailableView()
}
