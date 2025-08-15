//
//  ConnectionEditSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.08.25.
//

import SwiftUI
import ShelfPlayback

struct ConnectionEditSheet: View {
    @Environment(Satellite.self) private var satellite
    
    let connectionID: ItemIdentifier.ConnectionID
    
    @State private var viewModel: ViewModel?
    @State private var notifyError = false
    
    private var isLoading: Bool {
        viewModel?.isLoading ?? false
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    @Bindable var viewModel = viewModel
                    
                    List {
                        Section {
                            
                        }
                        
                        #if DEBUG
                        CertificateEditor(identity: .constant(nil))
                        #endif
                        
                        HeaderEditor(headers: $viewModel.headers)
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("action.save") {
                                viewModel.save {
                                    satellite.dismissSheet()
                                }
                            }
                            .disabled(isLoading)
                        }
                    }
                } else {
                    LoadingView()
                        .onAppear {
                            Task {
                                do {
                                    self.viewModel = try await ViewModel(connectionID: connectionID)
                                } catch {
                                    notifyError.toggle()
                                }
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .sensoryFeedback(.error, trigger: notifyError)
    }
}

@MainActor @Observable
private final class ViewModel: Sendable {
    let connectionID: ItemIdentifier.ConnectionID
    
    var headers: [HeaderShadow]
    
    var isLoading = false
    
    init(connectionID: ItemIdentifier.ConnectionID) async throws {
        self.connectionID = connectionID
        
        let headers = try await PersistenceManager.shared.authorization.headers(for: connectionID)
        self.headers = headers.map { .init(key: $0.key, value: $0.value) }
    }
    
    nonisolated func save(_ callback: @MainActor @escaping () -> Void) {
        Task {
            let headers = await MainActor.run {
                isLoading = true
                return self.headers.compactMap(\.materialized)
            }
            
            try! await PersistenceManager.shared.authorization.updateConnection(connectionID, headers: headers)
            
            await MainActor.withAnimation {
                isLoading = false
                callback()
            }
        }
    }
}

#if DEBUG
#Preview {
    ConnectionEditSheet(connectionID: "fixture")
        .previewEnvironment()
}
#endif
