//
//  MigrationView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayerMigration

struct MigrationView: View {
    @Environment(Satellite.self) private var satellite

    @Binding var migrationState: MigrationManager.State

    @State private var progress: Double = 0
    @State private var migrationTask: Task<Void, Never>?

    private var isFailed: Bool {
        if case .failed = migrationState { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "shippingbox.and.arrow.backward")
                .font(.system(size: 64))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.tint)
                .padding(.bottom, 20)

            Text("migration.title")
                .bold()
                .font(.title)
                .padding(.bottom, 8)

            Text("migration.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Group {
                if isFailed {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("migration.failed")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                } else {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 40)
                }
            }
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if isFailed {
                    Button("preferences.support", systemImage: "lifepreserver") {
                        satellite.present(.debugPreferences)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.extraLarge)
                    .buttonSizing(.flexible)
                    .padding(.horizontal, 20)
                    
                    Button("migration.retry") {
                        startMigration()
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.extraLarge)
                    .buttonSizing(.flexible)
                    .padding(.horizontal, 20)
                } else {
                    Text("migration.doNotClose")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            startMigration()
        }
    }

    private func startMigration() {
        // Cancel any in-flight migration so a retry doesn't run a second one concurrently.
        migrationTask?.cancel()

        migrationTask = Task {
            // Poll progress for the duration of the migration; stops automatically
            // once the migration finishes (or the task is cancelled).
            let pollingTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(100))

                    let current = await MigrationManager.shared.state
                    migrationState = current

                    if case .inProgress(let value) = current {
                        progress = value
                    }
                }
            }

            defer { pollingTask.cancel() }

            do {
                try await MigrationManager.shared.performMigration()
            } catch {
                // Final state is read below regardless of success or failure.
            }

            migrationState = await MigrationManager.shared.state
        }
    }
}

#if DEBUG
#Preview("In Progress") {
    MigrationView(migrationState: .constant(.inProgress(0.4)))
        .previewEnvironment()
}

#Preview("Failed") {
    MigrationView(migrationState: .constant(.failed(URLError(.unknown))))
        .previewEnvironment()
}

#Preview("Starting") {
    MigrationView(migrationState: .constant(.available))
        .previewEnvironment()
}
#endif
