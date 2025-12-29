//
//  Description.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

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
                        .padding(.horizontal, -5)
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
        textView.textContainerInset = .zero
        
        delegate.callback = {
            handleURL($0)
        }
        textView.delegate = delegate
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let data = Data(self.html.utf8)
            
            do {
                var attributedString = try NSMutableAttributedString(data: data, options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ], documentAttributes: nil)
                
                attribute?(&attributedString)
                
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


#Preview {
    ScrollView {
        Description(description: """
            <u>Hello, World!</u>

            <a href="https://rfk.io">RFK</a>

            <br />
            <br />

            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Sed vulputate odio ut enim. Cras semper auctor neque vitae. Tortor vitae purus faucibus ornare suspendisse. Sed vulputate mi sit amet mauris. Morbi leo urna molestie at elementum eu facilisis. Condimentum vitae sapien pellentesque habitant morbi tristique senectus. Viverra ipsum nunc aliquet bibendum enim. Aliquet nec ullamcorper sit amet risus nullam eget felis eget. Feugiat nibh sed pulvinar proin. Mauris rhoncus aenean vel elit. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Integer enim neque volutpat ac tincidunt vitae semper. Vitae tortor condimentum lacinia quis vel eros donec ac. Ornare aenean euismod elementum nisi quis eleifend quam adipiscing vitae. Interdum posuere lorem ipsum dolor sit amet consectetur. Mattis molestie a iaculis at erat pellentesque. Sed faucibus turpis in eu. Elit eget gravida cum sociis natoque penatibus et. Nisi quis eleifend quam adipiscing vitae proin.
""")
            .padding()
    }
}

#Preview {
    Description(description: nil)
}
