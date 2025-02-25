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
    
    let item: PlayableItem
    let tint: Bool
    
    @State private var progress: ProgressTracker
    
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        _progress = .init(initialValue: .init(itemID: item.id))
    }
    
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    private var isLoading: Bool {
        satellite.isLoading(observing: item.id)
    }
    
    @ViewBuilder
    private var markAsFinishedButton: some View {
        Button("progress.finished.set", systemImage: "checkmark.square") {
            satellite.markAsFinished(item)
        }
    }
    
    @ViewBuilder
    private var markAsUnfinishedButton: some View {
        Button {
            satellite.markAsUnfinished(item)
        } label: {
            Label("progress.finished.unset", systemImage: "minus.square")
            
            if let finishedAt = progressEntity?.finishedAt {
                Text("finished.ago") + Text(finishedAt, style: .relative)
            }
        }
    }
    
    var body: some View {
        Group {
            if !isLoading, let entity = progress.entity {
                if entity.isFinished {
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
                    .tint(progress.entity?.isFinished == true ? .red : .green)
            } else {
                $0
            }
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture, tint: false)
}
#Preview {
    ProgressButton(item: Episode.fixture, tint: true)
}
#endif
