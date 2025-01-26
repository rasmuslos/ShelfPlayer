//
//  ItemDisplayTypePicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemDisplayTypePicker: View {
    @Binding var displayType: ItemDisplayType
    
    var body: some View {
        ControlGroup {
            ForEach(ItemDisplayType.allCases) { displayType in
                Button {
                    withAnimation {
                        self.displayType = displayType
                    }
                } label: {
                    Label(displayType.label, systemImage: displayType.icon)
                }
            }
        }
    }
}

extension ItemDisplayType {
    var label: LocalizedStringKey {
        switch self {
        case .grid:
            "display.grid"
        case .list:
            "display.list"
        }
    }
    
    var icon: String {
        switch self {
        case .grid:
            "square.grid.2x2"
        case .list:
            "list.bullet"
        }
    }
}

#Preview {
    ItemDisplayTypePicker(displayType: .constant(.list))
}

#Preview {
    Menu(String("Options")) {
        ItemDisplayTypePicker(displayType: .constant(.list))
    }
}
