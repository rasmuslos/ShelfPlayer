//
//  CircularProgressIndicator.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 16.02.25.
//

import SwiftUI
import ShelfPlayback

struct CircularProgressIndicator: View {
    let completed: Percentage
    
    let background: Color
    let tint: Color
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: CGFloat(completed), to: 360 - CGFloat(completed))
                .stroke(background, lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: CGFloat(completed))
                .stroke(tint, style: .init(lineWidth: 3, lineCap: .round))
        }
        .rotationEffect(.degrees(-90))
    }
}
