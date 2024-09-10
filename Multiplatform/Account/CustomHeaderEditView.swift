//
//  CustomHeaderEditView.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.03.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct CustomHeaderEditView: View {
    @State private var current = AudiobookshelfClient.shared.customHTTPHeaders
    
    let backButtonVisible: Bool
    let dismiss: (() -> Void)
    
    private var trimmed: [AudiobookshelfClient.CustomHTTPHeader] {
        current.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }
    
    var body: some View {
        List {
            ForEach(Array(current.enumerated()), id: \.offset) { (index, pair) in
                Section {
                    Group {
                        TextField("login.customHTTPHeaders.key", text: .init(get: { pair.key }, set: { current[index].key = $0 }))
                        TextField("login.customHTTPHeaders.value", text: .init(get: { pair.value }, set: { current[index].value = $0 }))
                    }
                    .fontDesign(.monospaced)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    
                    Button(role: .destructive) {
                        current.remove(at: index)
                    } label: {
                        Text("login.customHTTPHeaders.remove")
                    }
                }
            }
        }
        .navigationTitle("login.customHTTPHeaders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if backButtonVisible {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("done", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    current.append(.init(key: "", value: ""))
                } label: {
                    Label("login.customHTTPHeaders.add", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                
                Button {
                    AudiobookshelfClient.shared.customHTTPHeaders = trimmed
                    dismiss()
                } label: {
                    Label("login.customHTTPHeaders.save", systemImage: "checkmark")
                        .labelStyle(.titleOnly)
                }
            }
        }
        .onAppear {
            if current.isEmpty {
                current.append(.init(key: "", value: ""))
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomHeaderEditView(backButtonVisible: true) {}
    }
}
