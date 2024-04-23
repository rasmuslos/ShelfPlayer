//
//  Slider.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI

struct Slider: View {
    @Binding var percentage: Double
    @Binding var dragging: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundStyle(.tertiary)
                Rectangle()
                    .foregroundStyle(dragging ? Color.primary : Color.primary.opacity(0.8))
                    .frame(width: geometry.size.width * CGFloat(max(0, min(1, self.percentage / 100))))
            }
            .cornerRadius(7)
            .highPriorityGesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    withAnimation(.spring) {
                        percentage = min(max(0, Double(value.location.x / geometry.size.width * 100)), 100)
                        dragging = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring) {
                        dragging = false
                    }
                }
            )
        }
        .frame(height: dragging ? 10 : 7)
        .accessibilityRepresentation {
            SwiftUI.Slider(value: .init(get: { percentage * 100 }, set: { percentage = $0 / 100 }), in: 0...100)
        }
    }
}

#Preview {
    VStack {
        Slider(percentage: .constant(50), dragging: .constant(false))
            .padding(.horizontal, 20)
    }
}
