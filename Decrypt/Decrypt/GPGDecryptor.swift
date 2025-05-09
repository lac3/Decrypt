import Foundation
import ObjectivePGP

class GPGDecryptor {
    static func decrypt(data: Data, privateKeyData: Data, passphrase: String) -> Data? {
        do {
            let keys = try ObjectivePGP.readKeys(from: privateKeyData)
            // show first line of hexademical characters of privateKeyData
            print("privateKeyData:")
            let hexString = privateKeyData.map { String(format: "%02x", $0) }.joined()
            print(hexString.prefix(100))
            // show first line of hexademical characters of data
            print("data:")
            let hexStringData = data.map { String(format: "%02x", $0) }.joined()
            print(hexStringData.prefix(100))
            // show  passphrase
            print("passphrase:")
            print(passphrase)
            print("keys:")
            print(keys)
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
