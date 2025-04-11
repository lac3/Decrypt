# GPG Decrypt

## Introduction

A simple iOS app for decrypting GPG-encrypted files using private keys.

This app is designed to allow you to read on your iPhone, files that have been encrypted on your Mac using GPG. The workflow is:

1. Encrypt a file on your Mac using GPG
2. Transfer the encrypted file and your private key to your iPhone (using iCloud Drive, Dropbox, Google Drive, or any other cloud storage service)
3. Use this app to decrypt and view the file content on your iPhone

This is particularly useful for securely accessing sensitive documents on your iPhone without storing the decrypted content permanently on the device.

## Development Note

This app is written in Swift using mostly [vibe coding](https://en.wikipedia.org/wiki/Vibe_coding) (experimental/iterative development). While it works, some parts of the code might look a bit unconventional. The app uses [ObjectivePGP](https://github.com/krzyzanowskim/ObjectivePGP) for handling GPG encryption/decryption operations.

## Features

- Decrypt GPG-encrypted files
- Support for private key authentication
- Secure file handling with security-scoped resources
- Display-only decryption (no persistent storage of decrypted content)

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run on your device or simulator

## Usage

1. Select the encrypted file you want to decrypt
2. Select your private key file
3. Enter the passphrase for your private key
4. Tap "Decrypt" to decrypt the file
5. The decrypted content will be displayed on screen. It is not saved to your device.

## About GPG

GPG ([GNU Privacy Guard](https://gnupg.org/)) is a widely used open-source implementation of the OpenPGP standard.

This app only supports asymmetric encryption (public/private key). It cannot decrypt files that were encrypted using symmetric encryption (password-only encryption).

## MacOS Setup Instructions for encrypting a file using GPG

### Installing GPG on Mac OS

1. Install Homebrew if you don't have it:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install GPG:
   ```bash
   brew install gnupg
   ```

### Creating and Exporting Keys

1. Generate a new GPG key:
   ```bash
   gpg --full-generate-key
   ```
   - Choose option 1 (RSA and RSA)
   - Choose 4096 bits
   - Choose 0 (key does not expire)
   - Enter your name and email
   - Enter a secure passphrase

2. Export your private key (required for decryption on iPhone):
   ```bash
   gpg --export-secret-keys --armor your-email@example.com > private_key.asc
   ```
   - Replace `your-email@example.com` with the email you used when creating the key
   - Enter your passphrase when prompted
   - The private key will be saved to `private_key.asc`
   - Transfer this file to your iPhone for use with the app

### Encrypting a file:
   ```bash
   gpg --encrypt --recipient your-email@example.com your_file.txt
   ```
   - This creates `your_file.txt.gpg`
   - Transfer this encrypted file to your iPhone for decryption with the app

### Decrypting a file on Mac:
   ```bash
   gpg --decrypt your_file.txt.gpg > decrypted_file.txt
   ```
   - This will prompt for your private key passphrase
   - The decrypted content will be saved to `decrypted_file.txt`

### Transferring files to iPhone

You can transfer the encrypted file and private key to your iPhone using various cloud storage services:
- iCloud Drive
- Dropbox
- Google Drive
- OneDrive
- Or any other cloud storage service that provides iOS file access

Simply upload the files to your preferred service and access them through the Files app on your iPhone when using the GPG Decrypt app.

## File Types

The app supports the following file types:
- Encrypted files (.gpg)
- Private key files (.asc)

## Security

- All file operations use security-scoped resources
- Passphrase is never stored
- Files are copied to the app's documents directory for processing
- Decrypted content is only displayed and not saved to the device
- No persistent storage of sensitive information

## License

This project is available under the MIT license. 