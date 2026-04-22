//
//  PlaybackSleepTimerButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackSleepTimerButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    private var sleepTimerIntervals: [Double] { AppSettings.shared.sleepTimerIntervals }

    private func remainingSleepTime(at date: Date) -> Double? {
        if let sleepTimer = satellite.sleepTimer, case .interval(let expiresAt, _) = sleepTimer {
            return date.distance(to: expiresAt)
        }

        return nil
    }

    private func accessibilityValue(at date: Date) -> String {
        if let remainingSleepTime = remainingSleepTime(at: date) {
            return remainingSleepTime.formatted(.duration)
        }

        if let sleepTimer = satellite.sleepTimer {
            switch sleepTimer {
                case .chapters(let amount, _):
                    return String(localized: "sleepTimer.chapter") + " \(amount)"
                default:
                    break
            }
        }

        return 0.formatted(.duration)
    }

    @ViewBuilder
    private func menuContent() -> some View {
        if let sleepTimer = satellite.sleepTimer {
            switch sleepTimer {
                case .chapters(let amount, _):
                    ControlGroup {
                        Button("action.decrease", systemImage: "minus") {
                            if amount > 1 {
                                satellite.setSleepTimer(.chapters(amount - 1))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }

                        Text(amount, format: .number)

                        Button("action.increase", systemImage: "plus") {
                            satellite.setSleepTimer(.chapters(amount + 1))
                        }
                    }
                case .interval(let expiresAt, let extend):
                    let remainingSleepTime = Date.now.distance(to: expiresAt)

                    ControlGroup {
                        Button("action.decrease", systemImage: "minus") {
                            if remainingSleepTime > 60 {
                                satellite.setSleepTimer(.interval(expiresAt.advanced(by: -60), extend))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }

                        Button("action.increase", systemImage: "plus") {
                            satellite.setSleepTimer(.interval(expiresAt.advanced(by: 60), extend))
                        }
                    }
            }

            Divider()

            Button("playback.sleepTimer.extend", systemImage: "plus") {
                satellite.extendSleepTimer()
            }

            Button("playback.sleepTimer.cancel", systemImage: "alarm") {
                satellite.setSleepTimer(nil)
            }
        } else {
            if satellite.chapter != nil {
                Button("playback.sleepTimer.chapter", systemImage: "append.page") {
                    satellite.setSleepTimer(.chapters(1))
                }

                Divider()
            }

            ForEach(sleepTimerIntervals, id: \.hashValue) { interval in
                Button {
                    satellite.setSleepTimer(.interval(interval))
                } label: {
                    Text(interval, format: .duration(unitsStyle: .full, allowedUnits: [.minute, .hour]))
                }
            }
        }
    }

    @ViewBuilder
    private func label(at date: Date) -> some View {
        ZStack {
            Group {
                Image(systemName: "append.page")
                Image(systemName: "moon.zzz.fill")
            }
            .hidden()

            if let sleepTimer = satellite.sleepTimer {
                switch sleepTimer {
                    case .chapters(_, _):
                        Label("sleepTimer.chapter", systemImage: "append.page")
                    case .interval(_, _):
                        let remainingSleepTime = remainingSleepTime(at: date)

                        if let remainingSleepTime {
                            Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                                .fontDesign(.rounded)
                                .contentTransition(.numericText())
                                .modify(if: viewModel.expansionAnimationCount == 0) {
                                    $0
                                        .animation(.smooth, value: remainingSleepTime)
                                }
                        } else {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
            } else {
                Label("playback.sleepTimer", systemImage: "moon.zzz.fill")
            }
        }
        .padding(12)
        .contentShape(.rect(cornerRadius: 4))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Menu {
                menuContent()
            } label: {
                label(at: context.date)
            }
            .menuActionDismissBehavior(.disabled)
            .hoverEffect(.highlight)
            .padding(-12)
            .accessibilityLabel("playback.sleepTimer")
            .accessibilityValue(Text(accessibilityValue(at: context.date)))
        }
    }
}
