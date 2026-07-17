# 🧠 BrainWallet GPU Scanner

<div align="center">

![License](https://img.shields.io/badge/license-MIT-brightgreen)
![Release](https://img.shields.io/badge/release-v1.0.0-blue)
![GitHub last commit](https://img.shields.io/github/last-commit/ethicbrudhack/FastBrain-GPU-)
![GitHub issues](https://img.shields.io/github/issues/ethicbrudhack/FastBrain-GPU-)
![GPU](https://img.shields.io/badge/GPU-NVIDIA%20CUDA-brightgreen)
![Language](https://img.shields.io/badge/language-C%2B%2B%20%26%20CUDA-blue)

**High-performance BrainWallet generator and scanner powered by GPU**

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation) • [Usage](#-usage) • [Examples](#-examples) • [Performance](#-performance)

</div>

---


## 📖 What is BrainWallet?

A **BrainWallet** is a Bitcoin wallet where the private key is generated from a passphrase (a word, phrase, or sentence). Anyone who knows the passphrase can access the funds.

This tool allows you to:
- **Generate** millions of passphrases from wordlists
- **Scan** them against a database of Bitcoin addresses
- **Find** wallets with balances

All powered by **GPU acceleration** for maximum speed.
---
DONATE: bc1qps62cyk9f9unmdkc9k3ccj9e2h8ywfhg2j53ec

Built with ❤️ for the crypto research community.
---
##📥 Download: 

📥adresy_unique.bin: https://drive.google.com/file/d/1vTkDbWXIwtv2_V-_FnuW6QjonaCd_XSx/view?usp=drive_link

📥Gtable: https://drive.google.com/file/d/1IggsvXIFmHWjiw4Rh-bKAKwWJ0OYxL9l/view?usp=drive_link

🌐 Website: https://fastscangpu.duckdns.org/

💬 Telegram https://t.me/+39k4WcVDfYhiMWFk
```
## ✨ Features

### 🚀 High Performance
- **60+ million hashes/second** on RTX 4090
- **GPU acceleration** using CUDA
- **Batch processing** for minimal overhead
- **Memory-mapped files** for large databases

### 🧠 Smart Generator
- Combine **2, 3, or 4 words** from any wordlist
- **Numbers** (8-20 digits) automatically added
- **Special characters** (`!@#$%^&*()_+-=...`)
- **Leet speak** (a→4, e→3, i→1, o→0, s→5)
- **Case variations** (lower, UPPER, Capitalized, mIXED)
- **Any language** – Unicode support (English, Chinese, Arabic, Hindi, etc.)

### 🎯 Easy to Use
- **Single command** to run
- **Text file input** – any words, any source
- **No configuration** needed
- **Real-time progress** display
---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/brainwallet-gpu-scanner](https://github.com/ethicbrudhack/FastBrain-GPU-.git
cd brainwallet-gpu-scanner

# 2. Compile
make

# 3. Prepare wordlist
echo "bitcoin" > words.txt
echo "wallet" >> words.txt

# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential nvidia-cuda-toolkit \
    libssl-dev libsecp256k1-dev

# Arch Linux
sudo pacman -S base-devel cuda openssl secp256k1

# macOS (CPU only)
brew install openssl secp256k1
echo "crypto" >> words.txt
echo "password" >> words.txt

# 4. Run scanner
./generator_advanced words -f words.txt -w 2 | ./brainwallet_gpu - adresy.bin

📝 Usage
Basic Commands:
# ============================================================
# 2-WORD COMBINATIONS - BASIC
# ============================================================

# 1. Basic 2-word combinations only
./generator_advanced words -f words.txt -w 2

# 2. 2 words + numbers at the end
./generator_advanced words -f words.txt -w 2 -n

# 3. 2 words + special characters
./generator_advanced words -f words.txt -w 2 -s

# 4. 2 words + leet speak (a→4, e→3, i→1, o→0, s→5)
./generator_advanced words -f words.txt -w 2 -leet

# 5. 2 words + case variations (lower, UPPER, Capitalized, mIXED)
./generator_advanced words -f words.txt -w 2 -case

# 6. 2 words + numbers + special chars + leet (all combined)
./generator_advanced words -f words.txt -w 2 -n -s -leet

# 7. 2 words + everything (most advanced)
./generator_advanced words -f words.txt -w 2 -n -s -case -leet


# ============================================================
# OTHER COMBINATIONS & OPTIONS
# ============================================================

# 8. 3-word combinations with numbers
./generator_advanced words -f words.txt -w 3 -n

# 9. 4-word combinations with special characters
./generator_advanced words -f words.txt -w 4 -s

# 10. Numbers only (8 to 12 digits)
./generator_advanced numbers -l 8 12

# 11. Random phrases (1 million random combinations)
./generator_advanced random -f words.txt -count 1000000


# ============================================================
# SAVE & LIMIT OPTIONS
# ============================================================

# 12. Save to file instead of stdout
./generator_advanced words -f words.txt -w 2 -o output.txt

# 13. Limit combinations (e.g., only 1 million)
./generator_advanced words -f words.txt -w 2 -c 1000000


# ============================================================
# PIPING TO BRAINWALLET (GPU SCANNER)
# ============================================================

# 14. Generate 2 words and pipe to brainwallet
./generator_advanced words -f words.txt -w 2 | ./brainwallet_gpu - adresy_unique.bin

# 15. 2 words + numbers → brainwallet
./generator_advanced words -f words.txt -w 2 -n | ./brainwallet_gpu - adresy_unique.bin

# 16. 2 words + special characters → brainwallet
./generator_advanced words -f words.txt -w 2 -s | ./brainwallet_gpu - adresy_unique.bin

# 17. 2 words + leet speak → brainwallet
./generator_advanced words -f words.txt -w 2 -leet | ./brainwallet_gpu - adresy_unique.bin

# 18. 2 words + case variations → brainwallet
./generator_advanced words -f words.txt -w 2 -case | ./brainwallet_gpu - adresy_unique.bin

# 19. 2 words + everything → brainwallet (most advanced)
./generator_advanced words -f words.txt -w 2 -n -s -case -leet | ./brainwallet_gpu - adresy_unique.bin

# 20. Save to file AND pipe to brainwallet simultaneously
./generator_advanced words -f words.txt -w 2 | tee phrases.txt | ./brainwallet_gpu - adresy_unique.bin
📝 Option Description:
Option	What it does	Example
-w 2/3/4	Number of words in combination	-w 2 → 2 words
-n	Adds numbers (8-20 digits)	hello12345678
-s	Adds special characters	!hello, hello!
-leet	Letter-to-number conversion (leet speak)	h3ll0 (a→4, e→3)
-case	Case variations	hello, HELLO, Hello
-o file	Save to file	-o results.txt
-c number	Limit combinations	-c 1000000
-count number	Number of random phrases	-count 1000000
-l min max	Number length range	-l 8 12
💡 Quick Reference:
Goal	Command
Fast scan	./generator_advanced words -f words.txt -w 2 | ./brainwallet_gpu - adresy.bin
With numbers	./generator_advanced words -f words.txt -w 2 -n | ./brainwallet_gpu - adresy.bin
With everything	./generator_advanced words -f words.txt -w 2 -n -s -leet -case | ./brainwallet_gpu - adresy.bin
Numbers only	./generator_advanced numbers -l 8 12 | ./brainwallet_gpu - adresy.bin
Random phrases	./generator_advanced random -f words.txt -count 1000000 | ./brainwallet_gpu - adresy.bin
Save to file	./generator_advanced words -f words.txt -w 2 -o output.txt
Random Phrases
bash
# Generate 1 million random phrases
./generator_advanced random -f words.txt -count 1000000 | ./brainwallet_gpu - adresy.bin
Save Results
bash
# Save to file (no scanning)
./generator_advanced words -f words.txt -w 2 -o output.txt

# Save and scan
./generator_advanced words -f words.txt -w 2 | tee output.txt | ./brainwallet_gpu - adresy.bin

# View found keys
cat found_brainwallet.txt
📊 Performance
GPU	Speed	Combinations/sec
RTX 4090	63 MH/s	63,000,000
RTX 3090	45 MH/s	45,000,000
RTX 3080	35 MH/s	35,000,000
RTX 2080 Ti	20 MH/s	20,000,000
Speed Comparison
Words	Combos	Time at 63 MH/s
100	10,000	0.00016 sec
1,000	1,000,000	0.016 sec
5,000	25,000,000	0.4 sec
13,317	177,342,489	2.8 sec
🗂️ Wordlists
Download Popular Wordlists
bash
# English words (5000+)
git clone https://github.com/ClaraRastelli/most-common-words-multilingual.git

# Use the English wordlist
cp most-common-words-multilingual/data/wordfrequency.info/en.txt words.txt

# Other languages
cp most-common-words-multilingual/data/wordfrequency.info/hi.txt words.txt    # Hindi
cp most-common-words-multilingual/data/wordfrequency.info/ar.txt words.txt    # Arabic
cp most-common-words-multilingual/data/wordfrequency.info/zh-CN.txt words.txt # Chinese
cp most-common-words-multilingual/data/wordfrequency.info/tr.txt words.txt    # Turkish
Create Custom Wordlist
bash
# Any text file with one word per line
echo "password" >> words.txt
echo "bitcoin" >> words.txt
echo "wallet" >> words.txt
echo "crypto" >> words.txt

# From Bible quotes
cat bible_quotes.txt | tr ' ' '\n' | sort -u > words.txt

# From any source
cat any_file.txt | grep -o '\w\+' | sort -u > words.txt
🔧 Configuration
Adjust Performance
Edit the constants in brainwallet_gpu.cu:

cpp
#define MAX_FOUND_KEYS 2000000      // Max keys to store
#define MAX_PASS_LEN 512            // Max password length
#define BLOCKS 32768                // GPU blocks (increase = faster)
#define THREADS 256                 // Threads per block (256 recommended)
#define BATCH_SIZE 5000000          // Batch size (5M recommended)
GPU Selection
bash
# Use specific GPU (if multiple)
export CUDA_VISIBLE_DEVICES=0

# Show GPU info
nvidia-smi
📁 Output Format
Found keys are saved to found_brainwallet.txt:

text
FRAZA: hello world
KEY: b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
TYP: COMPRESSED
ADDR: 12q7HJP6LFwMHFWCogVzjq7BsHt8tqWfur
---
FRAZA: test test
KEY: 03ffdf45276dd38ffac79b0e9c6c14d89d9113ad783d5922580f4c66a3305591
TYP: UNCOMPRESSED
ADDR: 16HAMWkcJuTyXeXxGnNEsAVaJVtyr9SNhZ
---
⚠️ Important Notes
Legality
This tool is for educational purposes only. Only scan wallets you own or have explicit permission to test.

Wallet Balance
Found addresses may be empty wallets. Always check the balance before celebrating:

bash
curl https://blockchain.info/balance?active=12q7HJP6LFwMHFWCogVzjq7BsHt8tqWfur
Performance
RTX 4090 is significantly faster than older cards

60+ MH/s requires both code optimizations and proper hardware

CPU scanning is 1000x slower – GPU is mandatory for practicality

🐛 Troubleshooting
"No module named 'pyarrow'"
bash
pip install pyarrow pandas
Compilation errors
bash
# Make sure dependencies are installed
sudo apt install build-essential nvidia-cuda-toolkit libssl-dev libsecp256k1-dev
GPU not detected
bash
# Check if NVIDIA drivers are installed
nvidia-smi

# Install drivers if needed
sudo ubuntu-drivers autoinstall
sudo reboot
Out of memory
bash
# Reduce BATCH_SIZE in the code
#define BATCH_SIZE 1000000  # Reduce from 5M
📚 Resources
Bitcoin Brainwallet

Secp256k1 Documentation

CUDA Programming Guide

OpenSSL Documentation

🤝 Contributing
Fork the repository

Create a feature branch

Make your changes

Submit a pull request

Ideas for Contribution
Support for more cryptocurrencies

Better wordlist generation

Multi-GPU support

Web interface

GUI version

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Satoshi Nakamoto for Bitcoin

NVIDIA for CUDA

The open-source community

⭐ Star History
If you find this useful, please give it a ⭐ on GitHub!

