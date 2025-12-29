//
//  ListenedTodayLabel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import ShelfPlayback

struct ListenedTodayLabel: View {
    @Environment(ListenedTodayTracker.self) private var listenedTodayTracker
    
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
    private var color: Color {
        tintColor.color
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                Circle()
                    .trim(from: 0, to: availablePercentage)
                    .stroke(color, style: .init(lineWidth: strokeWidth(geometryProxy.size.width), lineCap: .round))
                    .opacity(0.2)
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .trim(from: 0, to: min(availablePercentage, max(0, availablePercentage * (CGFloat(listenedTodayTracker.totalMinutesListenedToday) / CGFloat(listenedTodayTracker.listenTimeTarget)))))
                    .stroke(color, style: .init(lineWidth: strokeWidth(geometryProxy.size.width), lineCap: .round))
                    .rotationEffect(.degrees(135))
                
                if listenedTodayTracker.todaySessionLoader.isLoading && listenedTodayTracker.totalMinutesListenedToday == 0 {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Text(listenedTodayTracker.totalMinutesListenedToday, format: .number)
                        .font(.system(size: geometryProxy.size.width / 2.2).smallCaps())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: false))
                }
                
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    Text(listenedTodayTracker.listenTimeTarget, format: .number)
                        .font(.system(size: geometryProxy.size.width / 3))
                        .foregroundStyle(color)
                        .opacity(0.72)
                }
                .accessibilityValue(Text(verbatim: "\(listenedTodayTracker.totalMinutesListenedToday) / \(listenedTodayTracker.listenTimeTarget)"))
            }
            .contentShape(.rect)
        }
        .padding(2)
        .aspectRatio(0.9, contentMode: .fit)
        .animation(.smooth, value: listenedTodayTracker.totalMinutesListenedToday)
        .compositingGroup()
        // .accessibilityLabel(Text(("statistics.listenedToday")))
    }
    
    struct AdjustMenuInner: View {
        @Environment(ListenedTodayTracker.self) private var listenedTodayTracker
        
        var body: some View {
            ControlGroup {
                Button("action.decrease", systemImage: "minus") {
                    guard listenedTodayTracker.listenTimeTarget > 1 else {
                        return
                    }
                    
                    listenedTodayTracker.listenTimeTarget -= 1
                }
                
                Button("action.increase", systemImage: "plus") {
                    listenedTodayTracker.listenTimeTarget += 1
                }
            }
        }
    }
}

struct ListenedTodayListRow: View {
    @Environment(ListenedTodayTracker.self) private var listenedTodayTracker
    
    var body: some View {
        HStack(spacing: 12) {
            ListenedTodayLabel()
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(TimeInterval(listenedTodayTracker.totalMinutesListenedToday) * 60, format: .duration(unitsStyle: .spellOut, allowedUnits: [.second, .minute, .hour], maximumUnitCount: 1, formattingContext: .beginningOfSentence))
                    .font(.headline)
                Text("statistics.listenedToday")
                    .font(.subheadline)
            }
            
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
    }
}

#if DEBUG
#Preview {
    ListenedTodayLabel()
        .frame(width: 22)
        .border(.red)
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
