//
//  CollectionConfiguration.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.05.25.
//

import SwiftUI

struct CollectionConfigurationSheet: View {
    var body: some View {
        NavigationStack {
            List {
                
            }
            .navigationTitle("item.collection.configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("action.save") {
                    
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            CollectionConfigurationSheet()
        }
}
