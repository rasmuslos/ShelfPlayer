//
//  ContentView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State var state: Step = AudiobookshelfClient.shared.isAuthorized ? .sessionImport : .login
    
    init() {
        // this is stupid
        let appearance = UINavigationBarAppearance()
        
        appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        switch state {
        case .login:
            LoginView() {
                state = .sessionImport
            }
        case .sessionImport:
            SessionsImportView() {
                state = .library
            }
        case .library:
            LibraryView()
        }
    }
}

// MARK: Helper

extension ContentView {
    enum Step {
        case login
        case sessionImport
        case library
    }
}

#Preview {
    ContentView()
}
