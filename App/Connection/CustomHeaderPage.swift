//
//  CustomHeaderPage.swift
//  ShelfPlayer
//

import SwiftUI

struct CustomHeaderPage: View {
    @Binding var headers: [HeaderShadow]

    var body: some View {
        Form {
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
                } footer: {
                    if index == 0 {
                        Text("connection.add.customHeaders.hint")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("connection.add.customHeaders.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("connection.modify.header.add") {
                    withAnimation {
                        headers.append(.init(key: "", value: ""))
                    }
                }
                .disabled(headers.last.map { !$0.isValid } ?? false)
            }
        }
        .onAppear {
            if headers.isEmpty {
                headers.append(.init(key: "", value: ""))
            }
        }
        .onDisappear {
            headers.removeAll { !$0.isValid }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CustomHeaderPage(headers: .constant([]))
    }
}
#endif
