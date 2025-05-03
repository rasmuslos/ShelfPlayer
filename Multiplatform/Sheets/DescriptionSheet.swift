//
//  DescriptionSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.03.25.
//

import SwiftUI
import SPFoundation

struct DescriptionSheet: View {
    let item: Item
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(spacing: 0) {
                    if let description = item.description {
                        Text(description)
                    } else {
                        Text("item.description.missing")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
        }
    }
}

#if DEBUG
#Preview {
    DescriptionSheet(item: Audiobook.fixture)
}

#Preview {
    DescriptionSheet(item: Person.authorFixture)
}
#endif
