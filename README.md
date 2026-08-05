# Crypt Bash

A CLI tool for fast, simple file encryption, decryption, and GPG key management using GnuPG, driven by a menu so you don't have to remember GPG's flags.

## Features

- **GPG Key Generation**: create a new key with adjustable strength (2048/3072/4096-bit)
- **List GPG Keys**: list and browse the keys you have
- **File Encryption**: protect files with GPG
- **File Decryption**: retrieve your encrypted files
- **Bulk Expired Key Deletion**: remove all expired GPG keys at once
- **Key Deletion**: select a key from the list and remove it
- **Package manager detection**: detects apt, dnf, yum, pacman, or zypper and offers to install GnuPG if it's missing

## Quick Start

**Requirements:** Bash, one of apt/dnf/yum/pacman/zypper (used to auto-install GnuPG if it's not already present).

```bash
git clone https://github.com/aethrox/cryptbash.git
cd cryptbash
chmod +x cryptb.sh
./cryptb.sh
```

## Usage

Running `./cryptb.sh` opens a menu:

```
1) Create a GPG key
2) List GPG keys
3) Encrypt a file
4) Decrypt a file
5) Delete expired keys
6) Delete key
7) Exit
```

Follow the prompts for each operation. Encrypt/decrypt operations ask for an output path and offer to create missing directories or avoid overwriting existing files.

## Limitations

- Interactive only: there's no non-interactive/scripted mode (no flags to pass a file path or key ID directly).
- Only tested against the package managers listed above; other distros or non-Linux systems (macOS, BSD) aren't handled by the auto-install step.
- No automated tests in this repo; correctness relies on manual runs against a real GnuPG installation.

## License

MIT, see the [LICENSE](LICENSE) file.
