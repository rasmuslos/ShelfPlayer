//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    var showOfflineControls = false
    
    var body: some View {
        UnavailableWrapper {
            Inner()
        }
    }
    
    struct Inner: View {
        var body: some View {
            VStack(spacing: 0) {
                ProgressView()
                    .tint(.secondary)
                    .scaleEffect(2)
                    .frame(width: 40, height: 40)
                    .padding(.bottom, 8)
                
                Text("loading")
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LoadingView()
        .tint(.red)
}
