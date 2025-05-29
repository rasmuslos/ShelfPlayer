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
    
    private func strokeWidth(_ width: CGFloat) -> CGFloat {
        if width < 28 {
            2
        } else if width < 60 {
            4
        } else if width < 100 {
            6
        } else {
            20
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                Circle()
                    .trim(from: 0, to: availablePercentage)
                    .stroke(tintColor.color, lineWidth: strokeWidth(geometryProxy.size.width))
                    .opacity(0.2)
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .trim(from: 0, to: min(availablePercentage, max(0, availablePercentage * (CGFloat(progressViewModel.totalMinutesListenedToday) / CGFloat(progressViewModel.listenTimeTarget)))))
                    .stroke(tintColor.color, lineWidth: strokeWidth(geometryProxy.size.width))
                    .rotationEffect(.degrees(135))
                
                if progressViewModel.todaySessionLoader.isLoading && progressViewModel.totalMinutesListenedToday == 0 {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Text(progressViewModel.totalMinutesListenedToday, format: .number)
                        .font(.system(size: geometryProxy.size.width / 2.2).smallCaps())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: false))
                }
                
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    Text(progressViewModel.listenTimeTarget, format: .number)
                        .font(.system(size: geometryProxy.size.width / 3))
                        .foregroundStyle(tintColor.color)
                        .opacity(0.72)
                }
                .offset(x: 0, y: geometryProxy.size.width / 6)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring, value: progressViewModel.totalMinutesListenedToday)
        .compositingGroup()
    }
    
    struct AdjustMenuInner: View {
        @Environment(ProgressViewModel.self) private var progressViewModel
        
        var body: some View {
            ControlGroup {
                Button("action.decrease", systemImage: "minus") {
                    guard progressViewModel.listenTimeTarget > 1 else {
                        return
                    }
                    
                    progressViewModel.listenTimeTarget -= 1
                }
                
                Button("action.increase", systemImage: "plus") {
                    progressViewModel.listenTimeTarget += 1
                }
            }
        }
    }
}

struct ListenedTodayListRow: View {
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    var body: some View {
        Menu {
            ListenedTodayLabel.AdjustMenuInner()
        } label: {
            HStack(spacing: 12) {
                ListenedTodayLabel()
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(TimeInterval(progressViewModel.totalMinutesListenedToday) * 60, format: .duration(unitsStyle: .spellOut, allowedUnits: [.second, .minute, .hour], maximumUnitCount: 1))
                        .font(.headline)
                    Text("statistics.listenedToday")
                    
                        .font(.subheadline)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .menuActionDismissBehavior(.disabled)
    }
}

#if DEBUG
#Preview {
    ListenedTodayLabel()
        .frame(width: 22)
        .previewEnvironment()
}

#Preview {
    ListenedTodayLabel()
        .previewEnvironment()
}

#Preview {
    List {
        ListenedTodayListRow()
    }
    .previewEnvironment()
}

#Preview {
    Timeline(sessionLoader: .init(filter: .today))
        .previewEnvironment()
}
#endif
