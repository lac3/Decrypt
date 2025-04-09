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
    
    var body: some View {
        VStack {
            Button("Select File to Decrypt") {
                showFilePicker = true
            }
            
            if let selectedFile = selectedFile {
                Text("Selected file: \(selectedFile.lastPathComponent)")
            }
            
            Button("Select Private Key") {
                showKeyPicker = true
            }
            
            if let selectedPrivateKey = selectedPrivateKey {
                Text("Selected key: \(selectedPrivateKey.lastPathComponent)")
            }
            
            SecureField("Enter passphrase", text: $passphrase)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Decrypt") {
                decryptFile()
            }
            .disabled(selectedFile == nil || selectedPrivateKey == nil || passphrase.isEmpty || isDecrypting)
            
            if isDecrypting {
                ProgressView()
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !decryptedContent.isEmpty {
                ScrollView {
                    Text(decryptedContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
        }
        .padding()
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
            }, contentTypes: [.data, .text, .plainText])
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
            let privateKeyData = try Data(contentsOf: keyURL)
            
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
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isDecrypting = false
    }
} 