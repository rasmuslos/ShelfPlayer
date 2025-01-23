//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPFoundation
import SPPersistence

internal struct ProgressButton: View {
    let item: PlayableItem
    let tint: Bool
    let callback: (() -> Void)?
    
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    @State private var isLoading = false
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    init(item: PlayableItem, tint: Bool = false, callback: (() -> Void)? = nil) {
        self.item = item
        self.tint = tint
        self.callback = callback
    }
    
    @ViewBuilder
    private var markAsFinishedButton: some View {
        Button("progress.finished.set", systemImage: "checkmark") {
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
            Label("progress.finished.unset", systemImage: "minus")
            
            if let finishedAt = progressEntity?.finishedAt {
                Text("finished.ago") + Text(finishedAt, style: .relative)
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressIndicator()
            } else if let progressEntity {
                if progressEntity.isFinished {
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
        .symbolVariant(tint ? .none : .circle)
        .tint(tint ? progressEntity?.isFinished == true ? .red : .green : nil)
        .sensoryFeedback(.error, trigger: notifyError)
        .sensoryFeedback(.success, trigger: notifySuccess)
        .task {
            progressEntity = await PersistenceManager.shared.progress[item.id].updating
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture)
}
#endif
