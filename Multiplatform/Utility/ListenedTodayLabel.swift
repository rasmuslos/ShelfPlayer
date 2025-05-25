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
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
    @State private var loader = SessionLoader(filter: .today)
    @State private var cachedTimeSpendListening = 0.0
    
    private let availablePercentage: CGFloat = 0.75
    
    @Default(.listenTimeTarget) private var listenTimeTarget
    
    private var totalMinutes: Int {
        Int((loader.totalTimeSpendListening + cachedTimeSpendListening) / 60) + 16
    }
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: availablePercentage)
                .stroke(tintColor.color, lineWidth: 2)
                .opacity(0.2)
                .rotationEffect(.degrees(135))
                .frame(width: 22)
            
            Circle()
                .trim(from: 0, to: min(availablePercentage, max(0, availablePercentage * (CGFloat(totalMinutes) / CGFloat(listenTimeTarget)))))
                .stroke(tintColor.color, lineWidth: 2)
                .rotationEffect(.degrees(135))
                .frame(width: 22)
            
            if loader.isLoading && totalMinutes == 0 {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Text(totalMinutes, format: .number)
                    .font(.caption2.uppercaseSmallCaps())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: false))
            }
         
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                Text(listenTimeTarget, format: .number)
                    .font(.caption2.uppercaseSmallCaps())
                    .foregroundStyle(tintColor.color)
                    .opacity(0.72)
            }
            .offset(x: 0, y: 6)
        }
        .animation(.spring, value: totalMinutes)
        .onAppear {
            updateCachedTimeSpendListening()
        }
        .onReceive(RFNotification[.cachedTimeSpendListeningChanged].publisher()) {
            updateCachedTimeSpendListening()
            loader.refresh()
        }
    }
    
    private nonisolated func updateCachedTimeSpendListening() {
        Task {
            let cachedSessions = try await PersistenceManager.shared.session.totalUnreportedTimeSpentListening()
            let pendingOpen = await AudioPlayer.shared.pendingTimeSpendListening ?? 0
            
            await MainActor.run {
                self.cachedTimeSpendListening = cachedSessions + pendingOpen
            }
        }
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
