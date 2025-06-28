//
//  TimeRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.05.25.
//

import SwiftUI

struct TimeRow: View {
    @Environment(Satellite.self) private var satellite

    let title: String
    let time: TimeInterval
    
    let isActive: Bool
    let isFinished: Bool
    
    let callback: () -> Void
    
    var body: some View {
        Button {
            callback()
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    Text(verbatim: "00:00:00")
                        .hidden()
                    
                    Text(time, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                }
                .font(.footnote)
                .fontDesign(.rounded)
                .foregroundStyle(Color.accentColor)
                .padding(.trailing, 12)
                
                Text(title)
                    .bold(isActive)
                    .foregroundStyle(isFinished ? .secondary : .primary)
                
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }
}

#if DEBUG
#Preview {
    List {
        TimeRow(title: "Test", time: 300, isActive: false, isFinished: false) {}
        TimeRow(title: "Test", time: 300, isActive: false, isFinished: true) {}
        TimeRow(title: "Test", time: 300, isActive: true, isFinished: false) {}
        TimeRow(title: "Test", time: 300, isActive: true, isFinished: true) {}
    }
    .listStyle(.plain)
    .previewEnvironment()
}
#endif
