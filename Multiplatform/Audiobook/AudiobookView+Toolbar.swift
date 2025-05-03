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
                            HeroBackButton()
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if !viewModel.supplementaryPDFs.isEmpty {
                            if viewModel.loadingPDF {
                                ProgressView()
                            } else {
                                if viewModel.supplementaryPDFs.count == 1 {
                                    Button("item.documents.read", systemImage: "book.circle") {
                                        viewModel.presentPDF(viewModel.supplementaryPDFs[0])
                                    }
                                } else {
                                    Menu("item.documents.read", systemImage: "book.circle") {
                                        ForEach(viewModel.supplementaryPDFs) { pdf in
                                            Button(pdf.name) {
                                                viewModel.presentPDF(pdf)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        DownloadButton(itemID: viewModel.audiobook.id, progressVisibility: .toolbar)
                            .labelStyle(.iconOnly)
                        
                        Menu {
                            QueuePlayButton(itemID: viewModel.audiobook.id)
                            QueueButton(itemID: viewModel.audiobook.id)
                            
                            Divider()
                            
                            DownloadButton(itemID: viewModel.audiobook.id)
                            
                            Divider()
                            
                            ItemMenu(authors: viewModel.audiobook.authors)
                            ItemMenu(narrators: viewModel.audiobook.narrators)
                            ItemMenu(series: viewModel.audiobook.series)
                            
                            Divider()
                            
                            ProgressButton(itemID: viewModel.audiobook.id)
                            ProgressResetButton(itemID: viewModel.audiobook.id)
                        } label: {
                            Label("item.options", systemImage: "ellipsis.circle")
                        }
                    }
                }
                .fullScreenCover(isPresented: pdfBinding) {
                    NavigationStack {
                        PDFViewer(viewModel.presentedPDF!)
                            .toolbar {
                                ToolbarItem(placement: .primaryAction) {
                                    Button("action.dismiss") {
                                        viewModel.presentedPDF = nil
                                    }
                                }
                            }
                    }
                }
        }
    }
}
