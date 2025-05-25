//
//  ListenedTodayLabel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import ShelfPlayerKit
import Defaults

struct ListenedTodayLabel: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
    @State private var loader = SessionLoader(filter: .today)
    
    private var totalMinutes: Int {
        Int((loader.totalTimeSpendListening + satellite.unreportedTimeSpendListening) / 60)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(0.5))
                .stroke(tintColor.color, lineWidth: 2)
                .rotationEffect(Angle(degrees: -90))
                .frame(width: 22)
            
            if loader.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Text(totalMinutes, format: .number)
                    .font(.caption2.uppercaseSmallCaps())
                    .foregroundStyle(tintColor.color)
                    .contentTransition(.numericText(countsDown: false))
            }
        }
        .animation(.spring, value: totalMinutes)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Text(verbatim: ":)")
            .toolbar {
                Button {
                    
                } label: {
                    ListenedTodayLabel()
                }
                .buttonStyle(.plain)
                
                Label(String(""), systemImage: "circle")
            }
    }
    .previewEnvironment()
}

#Preview {
    Timeline(sessionLoader: .init(filter: .today))
        .previewEnvironment()
}
#endif
