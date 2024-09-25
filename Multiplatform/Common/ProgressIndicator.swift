//
//  ProgressIndicator.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import Defaults
import SPOffline

struct CircularProgressIndicator: View {
    @Default(.tintColor) private var tintColor
    
    let entity: ProgressEntity
    
    var body: some View {
        if entity.progress < 0 {
            EmptyView()
        } else {
            ZStack {
                if entity.isFinished {
                    Circle()
                        .fill(Color.accentColor.quaternary)
                    
                    Label("progress.completed", systemImage: "checkmark")
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
                            .trim(from: 0, to: CGFloat(entity.progress))
                            .stroke(tintColor.accent, style: StrokeStyle(lineWidth: proxy.size.width / 2))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: entity.progress)
                    }
                    .padding(2)
                }
            }
        }
    }
}
