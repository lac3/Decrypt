import Foundation
import ObjectivePGP

class GPGDecryptor {
    static func decrypt(data: Data, privateKeyData: Data, passphrase: String) -> Data? {
        do {
            let keys = try ObjectivePGP.readKeys(from: privateKeyData)
            print("Debug - imported \(keys.count) keys")
            let decrypted = try ObjectivePGP.decrypt(
                data,
                andVerifySignature: false,
                using: keys,
                passphraseForKey: { key in
                    return passphrase
                }
            )
            return decrypted
        } catch {
            print("Decryption failed: \(error)")
            if let pgpError = error as? PGPError {
                print("PGP Error details: \(pgpError)")
            }
            return nil
        }
    }
} 
