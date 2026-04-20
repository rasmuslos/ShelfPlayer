//
//  CarPlayPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.04.25.
//

import SwiftUI
import ShelfPlayback

struct CarPlayPreferences: View {
    @State private var carPlayTabBarLibraries: [Library]? = AppSettings.shared.carPlayTabBarLibraries
    @State private var carPlayShowOtherLibraries: Bool = AppSettings.shared.carPlayShowOtherLibraries

    private var showTabBarLimitWarning: Bool {
        guard let carPlayTabBarLibraries else {
            return false
        }

        let additionalTabs = 1
        return (carPlayTabBarLibraries.count + additionalTabs) > 5
    }

    var body: some View {
        List {
            SettingsPageHeader(title: "preferences.carPlay", systemImage: "car.fill", color: .green, subtitle: "preferences.carPlay.tabBar.footer")

            if showTabBarLimitWarning {
                Section {
                    Text("preferences.carPlay.tabBar.warning")
                        .foregroundStyle(.blue)
                }
            }

            Section {
                LibraryEnumerator { name, content in
                    Section(name) {
                        content()
                    }
                } label: { library in
                    Toggle(library.name, systemImage: library.icon, isOn: carPlayBinding(for: library))
                }
            }
            
            Section {
                Toggle("carPlay.otherLibraries", isOn: $carPlayShowOtherLibraries)
                    .onChange(of: carPlayShowOtherLibraries) { AppSettings.shared.carPlayShowOtherLibraries = carPlayShowOtherLibraries }
            }
        }
        .navigationTitle("preferences.carPlay")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: carPlayTabBarLibraries)
    }

    private func carPlayBinding(for library: Library) -> Binding<Bool> {
        Binding {
            carPlayTabBarLibraries?.contains(library) == true
        } set: { selected in
            withAnimation {
                if selected {
                    if carPlayTabBarLibraries == nil {
                        carPlayTabBarLibraries = [library]
                    } else {
                        carPlayTabBarLibraries?.append(library)
                    }
                } else {
                    carPlayTabBarLibraries?.removeAll { $0.id == library.id }
                    if carPlayTabBarLibraries?.isEmpty == true {
                        carPlayTabBarLibraries = nil
                    }
                }
                AppSettings.shared.carPlayTabBarLibraries = carPlayTabBarLibraries
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CarPlayPreferences()
    }
    .previewEnvironment()
}
#endif
