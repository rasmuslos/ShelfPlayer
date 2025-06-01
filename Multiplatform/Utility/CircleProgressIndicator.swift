//
//  ProgressIndicator.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct CircleProgressIndicator: View {
    @Default(.tintColor) private var tintColor
    
    let progress: Percentage
    
    var body: some View {
        if progress < 0 {
            EmptyView()
        } else {
            ZStack {
                if progress >= 1 {
                    Circle()
                        .fill(Color.accentColor.quaternary)
                    
                    Label(1.formatted(.percent.notation(.compactName)), systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .foregroundStyle(tintColor.accent)
                } else {
                    Circle()
                        .fill(Color.accentColor.quaternary)
                        .stroke(Color.accentColor.secondary, lineWidth: 1)
                    
                    GeometryReader { proxy in
                        Circle()
                            .inset(by: proxy.size.width / 4)
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(tintColor.accent, style: StrokeStyle(lineWidth: proxy.size.width / 2))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: progress)
                    }
                    .padding(2)
                }
            }
        }
    }
}
