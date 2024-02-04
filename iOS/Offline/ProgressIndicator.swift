//
//  ProgressIndicator.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPOffline

struct ProgressIndicator: View {
    let entity: OfflineProgress
    
    var body: some View {
        ZStack {
            if entity.progress >= 1 {
                Circle()
                    .fill(Color.accentColor.quaternary)
                
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.alternativeAccent)
            } else {
                Circle()
                    .fill(Color.accentColor.quaternary)
                    .stroke(Color.accentColor.secondary, lineWidth: 1)
                Circle()
                    .trim(from: 0, to: CGFloat(entity.progress))
                    .fill(.alternativeAccent)
                    .padding(2)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: entity.progress)
            }
        }
    }
}
