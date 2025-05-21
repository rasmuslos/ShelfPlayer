//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Nuke
import ShelfPlayerKit

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_CENTRALIZED
        ShelfPlayerKit.enableCentralized = false
        #endif
        
        ShelfPlayer.launchHook()
        
        // BackgroundTaskHandler.setup()
        // OfflineManager.shared.setupFinishedRemoveObserver()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if DEBUG
private struct ImageColorPreview: View {
    let images = ["circles", "house", "leaves", "painting", "shapes", "trees"]
    
    @AppStorage("preview-color-index") private var index = 0
    @State private var colors = [RFKVisuals.DominantColor]()
    
    @State private var threshold: CGFloat = 0.3
    
    private var brightnessFiltered: [Color] {
        RFKVisuals.brightnessExtremeFilter(colors.map(\.color), threshold: threshold)
    }
    private var saturationFiltered: [Color] {
        RFKVisuals.saturationExtremeFilter(colors.map(\.color), threshold: threshold)
    }
    
    var body: some View {
        VStack {
            Image(images[index])
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    print(threshold)
                    
                    colors = []
                    index = (index + 1) % images.count
                }
            
            Slider(value: $threshold, in: 0...1)
            
            HStack {
                ForEach(colors, id: \.color.hashValue) { color in
                    Rectangle()
                        .fill(color.color)
                        .overlay {
                            VStack {
                                Text(color.percentage, format: .number)
                                    .foregroundStyle(color.color.isLight == true ? .black : .white)
                                
                                Circle()
                                    .fill(brightnessFiltered.contains { $0 == color.color } ? .green : .red)
                                
                                Circle()
                                    .fill(saturationFiltered.contains { $0 == color.color } ? .green : .red)
                            }
                        }
                }
            }
            .onChange(of: index, initial: true) {
                Task {
                    colors = try! await RFKVisuals.extractDominantColors(10, image: UIImage(resource: ImageResource(name: images[index], bundle: .main))).sorted {
                        $0.percentage > $1.percentage
                    }
                    
                    for color in colors {
                        print("Percentage: \(color.percentage), Color: \(color.color)")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ImageColorPreview()
}
#endif
