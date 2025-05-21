//
//  PDFViewer.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.01.25.
//

import PDFKit
import SwiftUI

struct PDFViewer: UIViewRepresentable {
    typealias UIViewType = PDFView

    let data: Data
    let singlePage: Bool

    init(_ data: Data, singlePage: Bool = false) {
        self.data = data
        self.singlePage = singlePage
    }

    func makeUIView(context _: UIViewRepresentableContext<PDFViewer>) -> UIViewType {
        let pdfView = PDFView()
        
        pdfView.document = PDFDocument(data: data)
        
        pdfView.autoScales = true
        pdfView.displaysAsBook = true
        
        if singlePage {
            pdfView.displayMode = .singlePage
        }
        
        return pdfView
    }

    func updateUIView(_ pdfView: UIViewType, context _: UIViewRepresentableContext<PDFViewer>) {
        pdfView.document = PDFDocument(data: data)
    }
}
