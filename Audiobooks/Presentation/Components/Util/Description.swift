//
//  Description.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

struct Description: View {
    let description: String?
    
    @State var height = CGFloat.zero
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Description")
                    .bold()
                    .underline()
                    .padding(.bottom, 2)
                
                if let description = description {
                    HTMLTextView(height: $height, html: description)
                        .padding(.horizontal, -5)
                        .frame(height: height)
                } else {
                    Text("No description available")
                        .font(.body.smallCaps())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

struct HTMLTextView: UIViewRepresentable {
    @Binding var height: CGFloat
    
    let html: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)
        
        textView.backgroundColor = .clear
        textView.isEditable = false
        
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let data = Data(self.html.utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil) {
                textView.attributedText = attributedString
                textView.textColor = UIColor.label
                textView.font = UIFont.preferredFont(forTextStyle: .body)
            }
            
            height = textView.sizeThatFits(.init(
                width: UIScreen.main.bounds.width - 40,
                height: UIScreen.main.bounds.height)
            ).height
        }
    }
}

#Preview {
    ScrollView {
        Description(description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Sed vulputate odio ut enim. Cras semper auctor neque vitae. Tortor vitae purus faucibus ornare suspendisse. Sed vulputate mi sit amet mauris. Morbi leo urna molestie at elementum eu facilisis. Condimentum vitae sapien pellentesque habitant morbi tristique senectus. Viverra ipsum nunc aliquet bibendum enim. Aliquet nec ullamcorper sit amet risus nullam eget felis eget. Feugiat nibh sed pulvinar proin. Mauris rhoncus aenean vel elit. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Integer enim neque volutpat ac tincidunt vitae semper. Vitae tortor condimentum lacinia quis vel eros donec ac. Ornare aenean euismod elementum nisi quis eleifend quam adipiscing vitae. Interdum posuere lorem ipsum dolor sit amet consectetur. Mattis molestie a iaculis at erat pellentesque. Sed faucibus turpis in eu. Elit eget gravida cum sociis natoque penatibus et. Nisi quis eleifend quam adipiscing vitae proin.")
            .padding()
    }
}
