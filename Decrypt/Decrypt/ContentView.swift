import SwiftUI
import UniformTypeIdentifiers
import MobileCoreServices
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let contentTypes: [UTType]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access the file")
                return
            }
            
            // Make a local copy of the file
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let localURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                try FileManager.default.copyItem(at: url, to: localURL)
                parent.onPick(localURL)
            } catch {
                print("Error copying file: \(error)")
            }
            
            // Stop accessing the security-scoped resource
            url.stopAccessingSecurityScopedResource()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct ContentView: View {
    @State private var selectedFile: URL?
    @State private var selectedPrivateKey: URL?
    @State private var passphrase: String = ""
    @State private var decryptedContent: String = ""
    @State private var errorMessage: String = ""
    @State private var isDecrypting = false
    @State private var showFilePicker = false
    @State private var showKeyPicker = false
    @FocusState private var isPassphraseFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Files")) {
                    Button("Select File to Decrypt") {
                        showFilePicker = true
                    }
                    
                    if let selectedFile = selectedFile {
                        Text("Selected file: \(selectedFile.lastPathComponent)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Select Private Key") {
                        showKeyPicker = true
                    }
                    
                    if let selectedPrivateKey = selectedPrivateKey {
                        Text("Selected key: \(selectedPrivateKey.lastPathComponent)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Passphrase")) {
                    SecureField("Enter passphrase", text: $passphrase)
                        .focused($isPassphraseFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isPassphraseFocused = false
                        }
                }
                
                Section {
                    Button("Decrypt") {
                        isPassphraseFocused = false
                        decryptFile()
                    }
                    .disabled(selectedFile == nil || selectedPrivateKey == nil || passphrase.isEmpty || isDecrypting)
                    
                    if isDecrypting {
                        ProgressView()
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section(header: Text("Error")) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if !decryptedContent.isEmpty {
                    Section(header: Text("Decrypted Content")) {
                        Text(decryptedContent)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .navigationTitle("GPG Decrypt")
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker(onPick: { url in
                    selectedFile = url
                    errorMessage = ""
                    decryptedContent = ""
                }, contentTypes: [.data, .text, .plainText])
            }
            .sheet(isPresented: $showKeyPicker) {
                DocumentPicker(onPick: { url in
                    selectedPrivateKey = url
                    errorMessage = ""
                    decryptedContent = ""
                }, contentTypes: [.text, .plainText, .data])
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isPassphraseFocused = false
                    }
                }
            }
        }
    }
    
    private func hexDump(_ data: Data, prefix: String = "") {
        let bytesPerLine = 16
        let maxLines = 5
        for i in stride(from: 0, to: min(data.count, bytesPerLine * maxLines), by: bytesPerLine) {
            let lineBytes = data[i..<min(i + bytesPerLine, data.count)]
            let offset = String(format: "%07x", i)
            
            // Convert to array of bytes first
            let bytes = Array(lineBytes)
            let hexBytes = stride(from: 0, to: bytes.count, by: 2).map { j in
                if j + 1 < bytes.count {
                    return String(format: "%02x%02x", bytes[j+1], bytes[j])
                } else {
                    return String(format: "%02x", bytes[j])
                }
            }.joined(separator: " ")
            
            print("\(prefix)\(offset) \(hexBytes)")
        }
    }
    
    private func decryptFile() {
        guard let fileURL = selectedFile,
              let keyURL = selectedPrivateKey else { return }
        
        isDecrypting = true
        errorMessage = ""
        decryptedContent = ""
        
        do {
            let encryptedData = try Data(contentsOf: fileURL)
            // print("Encrypted file size: \(encryptedData.count) bytes")
            // print("Encrypted file content:")
            // hexDump(encryptedData)
            
            let privateKeyData = try Data(contentsOf: keyURL)
            // print("\nPrivate key size: \(privateKeyData.count) bytes")
            // print("Private key content:")
            // hexDump(privateKeyData)
            
            if let decryptedData = GPGDecryptor.decrypt(data: encryptedData, privateKeyData: privateKeyData, passphrase: passphrase) {
                if let text = String(data: decryptedData, encoding: .utf8) {
                    decryptedContent = text
                } else {
                    errorMessage = "Could not convert decrypted data to text"
                }
            } else {
                errorMessage = "Decryption failed"
            }
        } catch {
            // print("Error details: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isDecrypting = false
    }
} 
