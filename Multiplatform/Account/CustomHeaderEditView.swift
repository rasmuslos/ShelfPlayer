//
//  CustomHeaderEditView.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.03.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct CustomHeaderEditView: View {
    @State private var current = AudiobookshelfClient.shared.customHTTPHeaders
    
    var callback: (() -> Void)? = nil
    
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
            
            Group {
                Button {
                    current.append(.init(key: "", value: ""))
                } label: {
                    Label("login.customHTTPHeaders.add", systemImage: "plus")
                }
                Button {
                    AudiobookshelfClient.shared.customHTTPHeaders = current
                    callback?()
                } label: {
                    Label("login.customHTTPHeaders.save", systemImage: "checkmark")
                }
            }
            .foregroundStyle(.primary)
            
            if let callback = callback {
                Button(role: .destructive) {
                    AudiobookshelfClient.shared.customHTTPHeaders = current
                    callback()
                } label: {
                    Label("login.customHTTPHeaders.discard", systemImage: "minus")
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("login.customHTTPHeaders")
    }
}

#Preview {
    CustomHeaderEditView()
}

#Preview {
    CustomHeaderEditView() {
        
    }
}
