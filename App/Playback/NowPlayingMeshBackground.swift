//
//  NowPlayingMeshBackground.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.26.
//

import SwiftUI

struct NowPlayingMeshBackground: View {
    let colors: [Color]

    private static let dim = 3
    private static let speedMultiplier: Float = 15

    @State private var seeds: [DriftSeed] = (0..<Self.dim * Self.dim).map { _ in .random() }
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = Float(timeline.date.timeIntervalSince(startDate))

            MeshGradient(
                width: Self.dim, height: Self.dim,
                points: Self.driftedPoints(t: t, seeds: seeds),
                colors: colors
            )
        }
    }

    private static func driftedPoints(t: Float, seeds: [DriftSeed]) -> [SIMD2<Float>] {
        let drift: Float = 0.12
        let step = 1 / Float(dim - 1)
        var result: [SIMD2<Float>] = []
        result.reserveCapacity(dim * dim)

        for row in 0..<dim {
            for col in 0..<dim {
                let seed = seeds[row * dim + col]
                let baseX = Float(col) * step
                let baseY = Float(row) * step

                let xPinned = col == 0 || col == dim - 1
                let yPinned = row == 0 || row == dim - 1

                let dx: Float = xPinned ? 0 : drift * sin(t * seed.speedX * speedMultiplier + seed.phaseX)
                let dy: Float = yPinned ? 0 : drift * cos(t * seed.speedY * speedMultiplier + seed.phaseY)

                result.append(SIMD2(baseX + dx, baseY + dy))
            }
        }
        return result
    }

    private struct DriftSeed {
        let phaseX: Float
        let phaseY: Float
        let speedX: Float
        let speedY: Float

        static func random() -> DriftSeed {
            DriftSeed(
                phaseX: .random(in: 0...(2 * .pi)),
                phaseY: .random(in: 0...(2 * .pi)),
                speedX: .random(in: 0.04...0.10),
                speedY: .random(in: 0.04...0.10)
            )
        }
    }
}
