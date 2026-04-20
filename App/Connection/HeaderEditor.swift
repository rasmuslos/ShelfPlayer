//
//  HeaderEditor.swift
//  ShelfPlayer
//

import SwiftUI
import ShelfPlayback

struct HeaderEditor: View {
    @Binding var headers: [HeaderShadow]

    var body: some View {
        ForEach(Array(headers.enumerated()), id: \.offset) { (index, _) in
            Section {
                TextField("connection.modify.header.key", text: $headers[index].key)
                TextField("connection.modify.header.value", text: $headers[index].value)

                Button("connection.modify.header.remove", role: .destructive) {
                    let i = index
                    _ = withAnimation {
                        headers.remove(at: i)
                    }
                }
            } header: {
                if index == 0 {
                    Text("connection.modify.header")
                }
            }
        }

        Section {
            Button("connection.modify.header.add") {
                if let last = headers.last, !last.isValid {
                    return
                }

                withAnimation {
                    headers.append(.init(key: "X-", value: ""))
                }
            }
        }
    }
}

@Observable
final class HeaderShadow {
    var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    var isValid: Bool {
        !key.isEmpty && !value.isEmpty && key != "X-"
    }
    var materialized: HTTPHeader? {
        guard isValid else {
            return nil
        }
        return .init(key: key, value: value)
    }
}
