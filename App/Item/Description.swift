//
//  Description.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import UIKit

struct Description: View {
    @Environment(\.openURL) private var openURL

    typealias AttributeCallback = ((_: inout NSMutableAttributedString) -> Void)?

    let description: String?

    var showHeadline = true

    var attribute: AttributeCallback = nil
    var handleURL: ((URL) -> Bool)? = nil

    @State private var delegate = Delegate()
    @State private var height: CGFloat = .zero
    @State private var availableWidth: CGFloat = .zero

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        availableWidth = proxy.size.width
                    }
            }
            .frame(height: 0)

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    if showHeadline {
                        Text("item.description")
                            .bold()
                            .underline()
                            .padding(.bottom, 8)
                            .accessibilityAddTraits(.isHeader)
                    }

                    if let description {
                        HTMLTextView(height: $height, delegate: $delegate, html: description, width: availableWidth, attribute: attribute) {
                            if let handleURL {
                                handleURL($0)
                            } else {
                                true
                            }
                        }
                        .padding(.horizontal, -6)
                        .frame(height: height)
                    } else {
                        Text("item.description.missing")
                            .font(.body.smallCaps())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

private struct HTMLTextView: UIViewRepresentable {
    @Binding var height: CGFloat
    @Binding var delegate: Delegate

    let html: String
    let width: CGFloat

    let attribute: Description.AttributeCallback
    let handleURL: (URL) -> Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)

        textView.backgroundColor = .clear

        textView.isEditable = false

        textView.contentInset = .zero
        textView.layoutMargins = .zero
        textView.textContainerInset = .zero
        textView.showsHorizontalScrollIndicator = false

        delegate.callback = {
            handleURL($0)
        }
        textView.delegate = delegate

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let data = Data(html.utf8)

            do {
                var attributedString = try NSMutableAttributedString(data: data, options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ], documentAttributes: nil)

                attribute?(&attributedString)

                attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attributes, range, _ in
                    if attributes.keys.contains(.link) {
                        attributedString.removeAttribute(.underlineStyle, range: range)
                    }
                }

                textView.attributedText = attributedString
                textView.textColor = UIColor.label
                textView.font = UIFont.preferredFont(forTextStyle: .body)
            } catch {
                textView.attributedText = .init(string: "Failed to parse HTML")
            }

            height = textView.sizeThatFits(.init(
                width: width,
                height: 100_000)
            ).height
        }
    }
}

private final class Delegate: NSObject, UITextViewDelegate {
    var callback: ((URL) -> Bool)!

    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        if case .link(let url) = textItem.content {
            guard callback(url) else {
                return nil
            }
        }

        return defaultAction
    }
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        if case .link(let url) = textItem.content, url.scheme == "shelfPlayer" {
            return nil
        }

        return .init(menu: defaultMenu)
    }
}
