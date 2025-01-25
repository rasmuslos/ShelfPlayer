//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        @Environment(AudiobookViewModel.self) private var viewModel
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        private var pdfBinding: Binding<Bool> {
            .init { viewModel.presentedPDF != nil } set: {
                if !$0 {
                    viewModel.presentedPDF = nil
                }
            }
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(regularPresentation ? .automatic : viewModel.toolbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.toolbarVisible && !regularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.toolbarVisible {
                            VStack {
                                Text(viewModel.audiobook.name)
                                    .font(.headline)
                                    .modifier(SerifModifier())
                                    .lineLimit(1)
                                
                                if !viewModel.audiobook.authors.isEmpty {
                                    Text(viewModel.audiobook.authors, format: .list(type: .and, width: .short))
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                            .transition(.move(edge: .top))
                        } else {
                            Text(verbatim: "")
                        }
                    }
                }
                .toolbar {
                    if !viewModel.toolbarVisible && !regularPresentation {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(isToolbarVisible: viewModel.toolbarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if !viewModel.supplementaryPDFs.isEmpty {
                            if viewModel.loadingPDF {
                                ProgressIndicator()
                            } else {
                                if viewModel.supplementaryPDFs.count == 1 {
                                    Button("supplementaryPDF.read", systemImage: "book.circle") {
                                        viewModel.presentPDF(viewModel.supplementaryPDFs[0])
                                    }
                                } else {
                                    Menu("supplementaryPDF.read", systemImage: "book.circle") {
                                        ForEach(viewModel.supplementaryPDFs) { pdf in
                                            Button(pdf.name) {
                                                viewModel.presentPDF(pdf)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        DownloadButton(item: viewModel.audiobook, downloadingLabel: false, progressIndicator: true)
                            .labelStyle(.iconOnly)
                        
                        Menu {
                            Button {
                                viewModel.play()
                            } label: {
                                Label("queue.play", systemImage: "play.fill")
                            }
                            
                            QueueButton(item: viewModel.audiobook)
                            
                            Divider()
                            
                            AuthorMenu(authors: viewModel.audiobook.authors, libraryID: nil)
                            SeriesMenu(series: viewModel.audiobook.series, libraryID: nil)
                            
                            Divider()
                            
                            ProgressButton(item: viewModel.audiobook)
                            
                            if let progressEntity = viewModel.progressEntity, progressEntity.progress > 0 {
                                Button("progress.reset", systemImage: "slash.circle", role: .destructive, action: viewModel.resetProgress)
                            }
                            
                            /*
                             if viewModel.offlineTracker.status == .none {
                             ProgressButton(item: viewModel.audiobook)
                             DownloadButton(item: viewModel.audiobook)
                             } else {
                             if !viewModel.progressEntity.isFinished {
                             ProgressButton(item: viewModel.audiobook)
                             }
                             
                             Menu {
                             if viewModel.progressEntity.isFinished {
                             ProgressButton(item: viewModel.audiobook)
                             }
                             
                             if viewModel.progressEntity.startedAt != nil {
                             Button(role: .destructive) {
                             viewModel.resetProgress()
                             } label: {
                             Label("progress.reset", systemImage: "slash.circle")
                             }
                             }
                             
                             DownloadButton(item: viewModel.audiobook)
                             } label: {
                             Text("toolbar.remove")
                             }
                             }
                             */
                        } label: {
                            // Image(systemName: "ellipsis.circle")
                            Label("more", systemImage: "ellipsis.circle")
                        }
                    }
                }
                .fullScreenCover(isPresented: pdfBinding) {
                    NavigationStack {
                        PDFViewer(viewModel.presentedPDF!)
                            .toolbar {
                                ToolbarItem(placement: .primaryAction) {
                                    Button("done") {
                                        viewModel.presentedPDF = nil
                                    }
                                }
                            }
                    }
                }
        }
    }
}
