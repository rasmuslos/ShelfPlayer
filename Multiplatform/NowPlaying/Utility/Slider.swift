//
//  Slider.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal extension NowPlaying {
    struct Slider: View {
        @Environment(\.colorScheme) private var colorScheme
        
        @Binding var percentage: Percentage
        @Binding var dragging: Bool
        
        @State private var counter = 0
        @State private var blocked = false
        
        @State private var lastLocation: CGPoint? = nil
        
        var body: some View {
            ZStack {
                GeometryReader { geometry in
                    let width = geometry.size.width * min(1, max(0, CGFloat(percentage)))
                    
                    ZStack(alignment: .leading) {
                        if colorScheme == .dark {
                            Rectangle()
                                .fill(.background.tertiary)
                                .saturation(1.6)
                        } else {
                            Rectangle()
                                .fill(.background.secondary)
                                .saturation(1.6)
                        }
                        
                        Rectangle()
                            .frame(width: width)
                            .foregroundStyle(.primary)
                            .animation(.smooth, value: width)
                    }
                    .clipShape(.rect(cornerRadius: 8))
                    .highPriorityGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                        .onChanged { value in
                            if blocked {
                                return
                            }
                            
                            counter += 1
                            
                            if counter < 7 {
                                return
                            }
                            counter = 0
                            
                            dragging = true
                            blocked = true
                            
                            guard let lastLocation else {
                                lastLocation = value.location
                                blocked = false
                                
                                return
                            }
                            
                            let velocity = value.velocity.width
                            let acceleration: CGFloat
                            
                            if velocity < 100 {
                                acceleration = 0.8
                            } else if velocity > 300 {
                                acceleration = 1.5
                            } else {
                                acceleration = 1.2
                            }
                            
                            let delta = value.location.x - lastLocation.x
                            let offset = (delta / geometry.size.width) * acceleration
                            
                            self.lastLocation = value.location
                            
                            print(percentage, offset)
                            
                            percentage = min(1, max(0, percentage + offset))
                            blocked = false
                        }
                        .onEnded { _ in
                            dragging = false
                            lastLocation = nil
                        }
                    )
                }
                .frame(height: dragging ? 10 : 6)
                .secondaryShadow(radius: dragging ? 10 : 0, opacity: 0.2)
                .padding(20)
                .contentShape(.hoverMenuInteraction, .rect)
                .padding(-20)
                .animation(.spring, value: dragging)
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    @Previewable @State var dragging = false
    @Previewable @State var percentage = 0.5
    
    NowPlaying.Slider(percentage: $percentage, dragging: $dragging)
        .padding(.horizontal)
}
