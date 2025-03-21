//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPFoundation
import SPPersistence

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
        Button("progress.finished.set", systemImage: "checkmark.square") {
            satellite.markAsFinished(itemID)
        }
    }
    
    @ViewBuilder
    private var markAsUnfinishedButton: some View {
        Button {
            satellite.markAsUnfinished(itemID)
        } label: {
            Label("progress.finished.unset", systemImage: "minus.square")
            
            if let finishedAt = progress.finishedAt {
                Text("finished.ago \(finishedAt.formatted(.relative(presentation: .named)))")
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
                ProgressIndicator()
            }
        }
        .disabled(isLoading)
        .contentTransition(.symbolEffect)
        .modify {
            if tint {
                $0
                    .tint(progress.isFinished == true ? .red : .green)
            } else {
                $0
            }
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
