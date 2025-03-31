//
//  CreateLogArchiveButton.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.03.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateLogArchiveButton: View {
    @State private var isLoading = false
    
    @State private var isPresented = false
    @State private var document: LogArchiveDocument? = nil
    
    @State private var notifyError = false
    
    var body: some View {
        if isLoading {
            ProgressIndicator()
        } else {
            Button("preferences.generateLogFile", systemImage: "text.word.spacing") {
                createLogArchive()
            }
            .fileExporter(isPresented: $isPresented, document: document, contentType: .zip) { _ in
                document?.finalize()
            }
            .sensoryFeedback(.error, trigger: notifyError)
        }
    }
    
    private nonisolated func createLogArchive() {
        Task {
            await MainActor.withAnimation {
                isLoading = true
                isPresented = false
            }
            
            do {
                let url = try ShelfPlayer.generateLogArchive()
                
                await MainActor.withAnimation {
                    isLoading = false
                    
                    document = .init(url: url)
                    isPresented = true
                }
            } catch {
                await MainActor.withAnimation {
                    isLoading = false
                    document = nil
                    
                    notifyError.toggle()
                }
            }
        }
    }
}

private struct LogArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    init(configuration: ReadConfiguration) throws {
        fatalError("Unsupported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
    
    func finalize() {
        try? FileManager.default.removeItem(at: url)
    }
}

#Preview {
    CreateLogArchiveButton()
}
