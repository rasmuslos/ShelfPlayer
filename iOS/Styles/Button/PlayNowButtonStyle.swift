//
//  PlayNowButtonStyle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct PlayNowButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    let percentage: Double
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .background {
                ZStack {
                    if colorScheme == .dark {
                        Color.white
                    } else {
                        Color.black
                    }
                    
                    GeometryReader { geometry in
                        Rectangle()
                            .foregroundStyle(.secondary)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .padding(.horizontal, 20)
    }
}

#Preview {
    Button {
        
    } label: {
        Label(":)", systemImage: "command")
    }
    .buttonStyle(PlayNowButtonStyle(percentage: 0.5))
}
