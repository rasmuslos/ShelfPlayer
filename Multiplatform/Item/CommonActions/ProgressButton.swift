//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import ShelfPlayback

struct ProgressButton: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    let tint: Bool
    
    @State private var progress: ProgressTracker
    
    init(itemID: ItemIdentifier, tint: Bool = false) {
        self.itemID = itemID
        self.tint = tint
        
        _progress = .init(initialValue: .init(itemID: itemID))
    }
    
    private var isLoading: Bool {
        satellite.isLoading(observing: itemID)
    }
    
    @ViewBuilder
    private var markAsFinishedButton: some View {
        Button("item.progress.markAsFinished", systemImage: "checkmark.square") {
            satellite.markAsFinished(itemID)
        }
    }
    
    @ViewBuilder
    private var markAsUnfinishedButton: some View {
        Button {
            satellite.markAsUnfinished(itemID)
        } label: {
            Label("item.progress.markAsUnfinished", systemImage: "minus.square")
            
            if let finishedAt = progress.finishedAt {
                Text("item.progress.finished.ago \(finishedAt.formatted(.relative(presentation: .named)))", comment: "The system will display a relative date")
            }
        }
    }
    
    var body: some View {
        Group {
            if !isLoading, let isFinished = progress.isFinished {
                if isFinished {
                    markAsUnfinishedButton
                } else {
                    markAsFinishedButton
                }
            } else {
                Label("item.progress.resolving", systemImage: "square.dashed")
            }
        }
        .disabled(isLoading)
        .contentTransition(.symbolEffect)
        .modify(if: tint) {
            $0
                .tint(progress.isFinished == true ? .red : .green)
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(itemID: .fixture, tint: false)
}
#Preview {
    ProgressButton(itemID: .fixture, tint: true)
}
#endif
