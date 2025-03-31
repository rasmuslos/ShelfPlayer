//
//  HeaderEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import ShelfPlayerKit

struct HeaderEditor: View {
    @Binding var headers: [HeaderShadow]
    
    var body: some View {
        ForEach(Array(headers.enumerated()), id: \.offset) { (index, _) in
            HeaderEditorColumn(header: $headers[index]) {
                let _ = withAnimation {
                    headers.remove(at: index)
                }
            }
        }
        
        Button("connection.modify.header.add") {
            if let last = headers.last, !last.isValid {
                return
            }
            
            withAnimation {
                headers.append(.init(key: "", value: ""))
            }
        }
    }
}

struct HeaderEditorColumn: View {
    @Binding var header: HeaderShadow
    let remove: () -> Void
    
    var body: some View {
        Section {
            TextField("connection.modify.header.key", text: $header.key)
            TextField("connection.modify.header.value", text: $header.value)
            
            Button("connection.modify.header.remove", role: .destructive) {
                remove()
            }
        }
    }
}

@Observable @MainActor
final class HeaderShadow {
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    var isValid: Bool {
        !key.isEmpty && !value.isEmpty
    }
    var materialized: HTTPHeader? {
        guard isValid else {
            return nil
        }
        
        return .init(key: key, value: value)
    }
}
