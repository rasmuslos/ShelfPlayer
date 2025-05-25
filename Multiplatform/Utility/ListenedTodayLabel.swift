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
    @State private var cachedTimeSpendListening = 0.0
    
    private var targetMinutes: CGFloat {
        30
    }
    private var totalMinutes: Int {
        Int((loader.totalTimeSpendListening + cachedTimeSpendListening) / 60)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(totalMinutes) / targetMinutes)
                .stroke(tintColor.color, lineWidth: 2)
                .rotationEffect(Angle(degrees: -90))
                .frame(width: 22)
            
            if loader.isLoading && totalMinutes == 0 {
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
            let amount = try await PersistenceManager.shared.session.totalUnreportedTimeSpentListening()
            
            await MainActor.run {
                self.cachedTimeSpendListening = amount
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
