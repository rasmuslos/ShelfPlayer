//
//  CertificateEditor.swift
//  ShelfPlayer
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
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                if identity != nil {
                    Button(role: .destructive) {
                        identity = nil
                    } label: {
                        Label(String(localized: "connection.tlsClientCertificate.remove"), systemImage: "xmark.seal")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                } else {
                    Button {
                        isCertificateImporterPresented = true
                    } label: {
                        Label(String(localized: "connection.tlsClientCertificate.import"), systemImage: "checkmark.seal")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
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
                    .alert(String(localized: "connection.tlsClientCertificate.passphrase"), isPresented: $isPassphraseFieldPresented) {
                        TextField(String(localized: "connection.tlsClientCertificate.passphrase"), text: $passphrase)
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
                    .hapticFeedback(.error, trigger: notifyError)
                }
            }
            .background(.fill.tertiary, in: .rect(cornerRadius: 12))

            Text(String(localized: "connection.tlsClientCertificate.footer"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
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
