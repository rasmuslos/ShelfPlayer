//
//  TintPicker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import ShelfPlayback

struct TintPicker<Label: View>: View {
    @State private var tintColor: TintColor = AppSettings.shared.tintColor

    let onChanged: ((TintColor) -> Void)?
    let buildLabel: (_ : LocalizedStringKey, _ : String) -> Label

    init(onChanged: ((TintColor) -> Void)? = nil, @ViewBuilder buildLabel: @escaping (_ : LocalizedStringKey, _ : String) -> Label) {
        self.onChanged = onChanged
        self.buildLabel = buildLabel
    }

    var body: some View {
        Picker(selection: $tintColor) {
            Row(tint: .shelfPlayer, labelStyle: .titleOnly)

            Divider()

            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }) {
                Row(tint: $0, labelStyle: .titleOnly)
            }
        } label: {
            buildLabel("preferences.tint", "circle.dashed")
        }
        .onChange(of: tintColor) {
            AppSettings.shared.tintColor = tintColor
            onChanged?(tintColor)
            AppEventSource.shared.appearanceDidChange.send()
        }
    }

    struct Row<S: LabelStyle>: View {
        let tint: TintColor
        let labelStyle: S

        var body: some View {
            Button(tint.title, systemImage: "circle.fill") {
                AppSettings.shared.tintColor = tint
            }
            .buttonStyle(.plain)
            .labelStyle(labelStyle)
            .tag(tint)
            .foregroundStyle(tint.color)
            .symbolRenderingMode(.palette)
        }
    }
}

extension TintColor {
    var title: LocalizedStringKey {
        switch self {
            case .shelfPlayer:
                "preferences.tint.shelfPlayer"
            case .yellow:
                "preferences.tint.yellow"
            case .purple:
                "preferences.tint.purple"
            case .red:
                "preferences.tint.red"
            case .violet:
                "preferences.tint.violet"
            case .blue:
                "preferences.tint.blue"
            case .aqua:
                "preferences.tint.aqua"
            case .green:
                "preferences.tint.green"
            case .mint:
                "preferences.tint.mint"
            case .black:
                "preferences.tint.black"
        }
    }
}

#Preview {
    List {
        TintPicker {
            Label($0, systemImage: $1)
        }
    }
}
