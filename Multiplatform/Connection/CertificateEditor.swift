//
//  CertificateEditor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import SwiftUI
import Security
import ShelfPlayback

struct CertificateEditor: View {
    @Binding var identity: SecIdentity?
    
    @State private var isPassphraseFieldPresented = false
    @State private var isCertificateImporterPresented = false
    
    @State private var contents: Data? = nil
    @State private var passphrase = ""
    
    @State private var notifyError = false
    
    var body: some View {
        Section {
            if identity != nil {
                Button("connection.tlsClientCertificate.remove", systemImage: "xmark.seal", role: .destructive) {
                    identity = nil
                }
                .foregroundStyle(.red)
            } else {
                Button("connection.tlsClientCertificate.import", systemImage: "checkmark.seal") {
                    isCertificateImporterPresented = true
                }
                .foregroundStyle(.primary)
                .fileImporter(isPresented: $isCertificateImporterPresented, allowedContentTypes: [.pkcs12]) {
                    switch $0 {
                        case .success(let url):
                            guard url.startAccessingSecurityScopedResource(), let contents = try? Data(contentsOf: url) else {
                                notifyError.toggle()
                                return
                            }
                            
                            self.contents = contents
                            
                            isCertificateImporterPresented = false
                            isPassphraseFieldPresented = true
                            
                            url.stopAccessingSecurityScopedResource()
                        case .failure:
                            notifyError.toggle()
                    }
                }
                .alert("connection.tlsClientCertificate.passphrase", isPresented: $isPassphraseFieldPresented) {
                    TextField("connection.tlsClientCertificate.passphrase", text: $passphrase)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Button("action.cancel", role: .cancel) {
                        isPassphraseFieldPresented = false
                    }
                    Button("action.proceed") {
                        parseP12File()
                    }
                }
                .sensoryFeedback(.error, trigger: notifyError)
            }
        } footer: {
            Text("connection.tlsClientCertificate.footer")
        }
    }
    
    private func parseP12File() {
        do {
            guard let contents else {
                throw ParseError.missingCertificate
            }
            
            var rawItems: CFArray?
            
            let options = [
                kSecImportExportPassphrase as String: passphrase
            ]
            let status = SecPKCS12Import(contents as CFData, options as CFDictionary, &rawItems)
            
            guard status == errSecSuccess else {
                throw ParseError.securityServiceParseFailed
            }
            
            let items = rawItems! as! Array<Dictionary<String, Any>>
            
            guard let first = items.first, let identity = first[kSecImportItemIdentity as String] as! SecIdentity? else {
                throw ParseError.missingIdentity
            }
            
            self.identity = identity
        } catch {
            notifyError.toggle()
        }
        
        contents = nil
        passphrase = ""
        
        isPassphraseFieldPresented = false
        isCertificateImporterPresented = false
    }
    enum ParseError: Error {
        case missingIdentity
        case missingCertificate
        case securityServiceParseFailed
    }
}

#Preview {
    List {
        CertificateEditor(identity: .constant(nil))
    }
}
