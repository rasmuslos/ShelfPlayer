//
//  ListenedTodayLabel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import ShelfPlayerKit
import Defaults
import SPPlayback

struct ListenedTodayLabel: View {
    @Environment(ProgressViewModel.self) private var progressViewModel
    @Default(.tintColor) private var tintColor
    
    private let availablePercentage: CGFloat = 0.75
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: availablePercentage)
                .stroke(tintColor.color, lineWidth: 2)
                .opacity(0.2)
                .rotationEffect(.degrees(135))
                .frame(width: 22)
            
            Circle()
                .trim(from: 0, to: min(availablePercentage, max(0, availablePercentage * (CGFloat(progressViewModel.totalMinutesListenedToday) / CGFloat(progressViewModel.listenTimeTarget)))))
                .stroke(tintColor.color, lineWidth: 2)
                .rotationEffect(.degrees(135))
                .frame(width: 22)
            
            if progressViewModel.todaySessionLoader.isLoading && progressViewModel.totalMinutesListenedToday == 0 {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Text(progressViewModel.totalMinutesListenedToday, format: .number)
                    .font(.caption2.uppercaseSmallCaps())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: false))
            }
         
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                Text(progressViewModel.listenTimeTarget, format: .number)
                    .font(.caption2.uppercaseSmallCaps())
                    .foregroundStyle(tintColor.color)
                    .opacity(0.72)
            }
            .offset(x: 0, y: 6)
        }
        .animation(.spring, value: progressViewModel.totalMinutesListenedToday)
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
