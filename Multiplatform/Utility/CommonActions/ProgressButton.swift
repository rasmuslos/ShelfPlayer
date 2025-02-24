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
    let item: PlayableItem
    let tint: Bool
    
    let progress: ProgressTracker
    
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        progress = .init(itemID: item.id)
    }
    
    @State private var isLoading = false
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    @ViewBuilder
    private var markAsFinishedButton: some View {
        Button("progress.finished.set", systemImage: "checkmark.square") {
            Task {
                isLoading = true
                
                do {
                    try await PersistenceManager.shared.progress.markAsCompleted(item.id)
                    notifySuccess.toggle()
                } catch {
                    notifyError.toggle()
                }
                
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private var markAsUnfinishedButton: some View {
        Button {
            Task {
                isLoading = true
                
                do {
                    try await PersistenceManager.shared.progress.markAsListening(item.id)
                    notifySuccess.toggle()
                } catch {
                    notifyError.toggle()
                }
                
                isLoading = false
            }
        } label: {
            Label("progress.finished.unset", systemImage: "minus.square")
            
            if let finishedAt = progressEntity?.finishedAt {
                Text("finished.ago") + Text(finishedAt, style: .relative)
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressIndicator()
            } else if let entity = progress.entity {
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
        .sensoryFeedback(.error, trigger: notifyError)
        .sensoryFeedback(.success, trigger: notifySuccess)
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
