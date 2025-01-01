//
//  HeaderEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import RFNetwork

struct HeadersEditSection: View {
    @Binding var headers: [HeaderShadow]
    
    var body: some View {
        Section {
            Button("connection.header.add") {
                if let last = headers.last, !last.isValid {
                    return
                }
                
                withAnimation {
                    headers.append(.init(key: "", value: ""))
                }
            }
        }
        
        ForEach(Array(headers.enumerated()), id: \.offset) { (index, _) in
            HeaderEditColumn(header: $headers[index]) {
                let _ = withAnimation {
                    headers.remove(at: index)
                }
            }
        }
    }
}

struct HeaderEditColumn: View {
    @Binding var header: HeaderShadow
    let remove: () -> Void
    
    var body: some View {
        Section {
            TextField("connection.header.key", text: $header.key)
            TextField("connection.header.value", text: $header.value)
            
            Button("connection.header.remove", role: .destructive) {
                remove()
            }
        }
    }
}
