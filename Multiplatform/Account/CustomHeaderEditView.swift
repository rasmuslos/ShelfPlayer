//
//  CustomHeaderEditView.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.03.24.
//

import SwiftUI
import Defaults
import SPBase

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
            
            Button {
                current.append(.init(key: "", value: ""))
            } label: {
                Text("login.customHTTPHeaders.add")
            }
            Button {
                AudiobookshelfClient.shared.customHTTPHeaders = current
                callback?()
            } label: {
                Text("login.customHTTPHeaders.save")
            }
            
            if let callback = callback {
                Button(role: .destructive) {
                    AudiobookshelfClient.shared.customHTTPHeaders = current
                    callback()
                } label: {
                    Text("login.customHTTPHeaders.discard")
                }
            }
        }
        .navigationTitle("login.customHTTPHeaders")
    }
}

#Preview {
    CustomHeaderEditView()
}
