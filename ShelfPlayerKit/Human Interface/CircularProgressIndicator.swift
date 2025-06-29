//
//  CircularProgressIndicator.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 16.02.25.
//

import SwiftUI

public struct CircularProgressIndicator: View {
    let completed: Percentage
    
    let background: Color
    let tint: Color
    
    public init(completed: Percentage, background: Color, tint: Color) {
        self.completed = completed
        self.background = background
        self.tint = tint
    }
    
    public var body: some View {
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
