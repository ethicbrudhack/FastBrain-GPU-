// ============================================================
// FIX dla __builtin_dynamic_object_size (GCC 11+)
// ============================================================
#undef _FORTIFY_SOURCE
#define _FORTIFY_SOURCE 0

#ifndef __CUDA_ARCH__
#define __builtin_dynamic_object_size(p, i) __builtin_object_size(p, i)
#endif

#ifdef __CUDA_ARCH__
#undef _FORTIFY_SOURCE
#define _FORTIFY_SOURCE 0
#endif

// ============================================================
// INCLUDY
// ============================================================
#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <chrono>
#include <thread>
#include <iomanip>
#include <cuda_runtime.h>
#include <mutex>
#include <algorithm>
#include <openssl/sha.h>
#include <openssl/ripemd.h>
#include <openssl/bn.h>
#include <secp256k1.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "GPUSecp.h"
#include "GPUHash.h"
#include "GPUMath.h"

using namespace std;

// ============================================================
// STAŁE
// ============================================================
#define MAX_FOUND_KEYS 4000000
#define MAX_PASS_LEN 512
#define NUM_GTABLE_CHUNK 16
#define POINT_SIZE 32
#define BLOCKS 8192           // dostosuj do swojej karty
#define THREADS 128           // dostosuj
#define BATCH_SIZE 3000000   // 1M fraz na batch

// ============================================================
// MMAP
// ============================================================
class MMapFile {
public:
    MMapFile() : fd(-1), data(nullptr), size(0) {}
    explicit MMapFile(const char* path) : fd(-1), data(nullptr), size(0) { open_file(path); }
    void open_file(const char* path) {
        close_file();
        fd = ::open(path, O_RDONLY);
        if (fd < 0) throw std::runtime_error(std::string("open: ") + strerror(errno));
        struct stat st{};
        if (fstat(fd, &st) != 0) { int e = errno; ::close(fd); fd = -1; throw std::runtime_error(std::string("fstat: ") + strerror(e)); }
        size = (size_t)st.st_size;
        if (size == 0 || size % 20 != 0) { ::close(fd); fd = -1; throw std::runtime_error("invalid bin file (size must be multiple of 20)"); }
        data = (const unsigned char*) mmap(nullptr, size, PROT_READ, MAP_SHARED, fd, 0);
        if (data == MAP_FAILED) { int e = errno; data = nullptr; ::close(fd); fd = -1; throw std::runtime_error(std::string("mmap: ") + strerror(e)); }
        madvise((void*)data, size, MADV_WILLNEED);
    }
    void close_file() { if (data) { munmap((void*)data, size); data = nullptr; } if (fd >= 0) { ::close(fd); fd = -1; } size = 0; }
    ~MMapFile() { close_file(); }
    const unsigned char* ptr() const { return data; }
    size_t length() const { return size; }
    bool is_open() const { return data != nullptr; }
private:
    int fd; const unsigned char* data; size_t size;
};

// ============================================================
// FUNKCJE KONWERSJI (CPU) – identyczne jak w main.cu
// ============================================================
void sha256_once(const unsigned char* d, size_t n, unsigned char out[32]) {
    SHA256_CTX c; SHA256_Init(&c); SHA256_Update(&c, d, n); SHA256_Final(out, &c);
}
void ripemd160_once(const unsigned char* d, size_t n, unsigned char out[20]) {
    RIPEMD160_CTX r; RIPEMD160_Init(&r); RIPEMD160_Update(&r, d, n); RIPEMD160_Final(out, &r);
}
void pubkey_hash160(const unsigned char* pub, size_t len, unsigned char out[20]) {
    unsigned char sh[32]; sha256_once(pub, len, sh); ripemd160_once(sh, 32, out);
}
static const char* BASE58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
string base58_encode(const vector<unsigned char>& in) {
    BIGNUM* bn = BN_new(); BN_bin2bn(in.data(), in.size(), bn);
    BIGNUM *dv = BN_new(), *rem = BN_new(), *b58 = BN_new(); BN_CTX* ctx = BN_CTX_new(); BN_set_word(b58, 58);
    string out;
    while (!BN_is_zero(bn)) { BN_div(dv, rem, bn, b58, ctx); out.insert(out.begin(), BASE58[BN_get_word(rem)]); BN_copy(bn, dv); }
    for (unsigned char c : in) if (c == 0x00) out.insert(out.begin(), '1'); else break;
    BN_free(bn); BN_free(dv); BN_free(rem); BN_free(b58); BN_CTX_free(ctx);
    return out;
}
string addr_p2pkh(const unsigned char ripe[20]) {
    vector<unsigned char> ext; ext.push_back(0x00); ext.insert(ext.end(), ripe, ripe+20);
    unsigned char c1[32], c2[32]; sha256_once(ext.data(), ext.size(), c1); sha256_once(c1, 32, c2);
    ext.insert(ext.end(), c2, c2+4); return base58_encode(ext);
}
static const char* SECP256K1_ORDER_N_HEX = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141";
static bool reducePrivModOrderIfNeeded(unsigned char* priv) {
    BIGNUM* bn_priv = BN_new(); BIGNUM* bn_n = BN_new(); BIGNUM* bn_r = BN_new(); BN_CTX* bctx = BN_CTX_new();
    BN_bin2bn(priv, 32, bn_priv); BN_hex2bn(&bn_n, SECP256K1_ORDER_N_HEX); BN_mod(bn_r, bn_priv, bn_n, bctx);
    unsigned char reduced[32] = {0}; int len = BN_num_bytes(bn_r);
    if(len > 0) BN_bn2bin(bn_r, reduced + (32 - len));
    bool changed = (memcmp(priv, reduced, 32) != 0); memcpy(priv, reduced, 32);
    BN_free(bn_priv); BN_free(bn_n); BN_free(bn_r); BN_CTX_free(bctx);
    return changed;
}
static bool makeValidPubkey(secp256k1_context* ctx, secp256k1_pubkey* pub, unsigned char* priv) {
    if(secp256k1_ec_pubkey_create(ctx, pub, priv)) return true;
    reducePrivModOrderIfNeeded(priv);
    return secp256k1_ec_pubkey_create(ctx, pub, priv) != 0;
}
string keyToAddressCompressed(unsigned char* priv) {
    secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    secp256k1_pubkey pub;
    if(!makeValidPubkey(ctx, &pub, priv)) { secp256k1_context_destroy(ctx); return "INVALID_KEY"; }
    unsigned char pub_ser[33]; size_t pub_len = 33;
    secp256k1_ec_pubkey_serialize(ctx, pub_ser, &pub_len, &pub, SECP256K1_EC_COMPRESSED);
    unsigned char hash[20]; pubkey_hash160(pub_ser, 33, hash);
    string addr = addr_p2pkh(hash); secp256k1_context_destroy(ctx);
    return addr;
}
string keyToAddressUncompressed(unsigned char* priv) {
    secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    secp256k1_pubkey pub;
    if(!makeValidPubkey(ctx, &pub, priv)) { secp256k1_context_destroy(ctx); return "INVALID_KEY"; }
    unsigned char pub_ser[65]; size_t pub_len = 65;
    secp256k1_ec_pubkey_serialize(ctx, pub_ser, &pub_len, &pub, SECP256K1_EC_UNCOMPRESSED);
    unsigned char hash[20]; pubkey_hash160(pub_ser, 65, hash);
    string addr = addr_p2pkh(hash); secp256k1_context_destroy(ctx);
    return addr;
}

vector<uint8_t> loadFile(const char* path) {
    ifstream f(path, ios::binary | ios::ate);
    if(!f.is_open()) { cerr << "Nie moge otworzyc: " << path << "\n"; exit(1); }
    size_t size = f.tellg(); f.seekg(0, ios::beg);
    vector<uint8_t> data(size); f.read((char*)data.data(), size); f.close();
    return data;
}

// ============================================================
// GPU: SHA256 dla frazy (dokładnie tak jak w main.cu)
// ============================================================
__device__ void _SHA256Brainwallet(const uint8_t* input, uint16_t len, uint8_t output[32]) {
    uint32_t w[16] = {0};
    uint32_t s[8];

    for (int i = 0; i < len; i++) {
        int word = i >> 2;
        int shift = 24 - (i & 3) * 8;
        w[word] |= ((uint32_t)input[i]) << shift;
    }
    int byte_pos = len;
    if (byte_pos < 56) {
        w[byte_pos >> 2] |= 0x80 << (24 - (byte_pos & 3) * 8);
    } else {
        uint32_t w2[16] = {0};
        int remaining = len - 56;
        for (int i = 0; i < remaining; i++) {
            int word = i >> 2;
            int shift = 24 - (i & 3) * 8;
            w2[word] |= ((uint32_t)input[56 + i]) << shift;
        }
        w2[remaining >> 2] |= 0x80 << (24 - (remaining & 3) * 8);
        w2[15] = (len * 8) & 0xFFFFFFFF;
        _SHA256Initialize(s);
        _SHA256Transform(s, w);
        _SHA256Transform(s, w2);
        for (int i = 0; i < 8; i++) s[i] = bswap32(s[i]);
        memcpy(output, s, 32);
        return;
    }
    w[15] = (len * 8) & 0xFFFFFFFF;
    _SHA256Initialize(s);
    _SHA256Transform(s, w);
    for (int i = 0; i < 8; i++) s[i] = bswap32(s[i]);
    memcpy(output, s, 32);
}

// ============================================================
// GPU: Binary Search (z indeksem 24-bit)
// ============================================================
__device__ int _BinarySearch20(const uint8_t* buffer, uint64_t hi, const uint8_t* target) {
    uint64_t lo = 0;
    while (lo < hi) {
        uint64_t mid = (lo + hi) / 2;
        const uint8_t* addr = buffer + mid * 20;
        bool equal = true, less = false;
        for(int i = 0; i < 20; i++) { if(addr[i] != target[i]) { less = (addr[i] < target[i]); equal = false; break; } }
        if(equal) return (int)mid;
        else if(less) lo = mid + 1; else hi = mid;
    }
    return -1;
}
__device__ __forceinline__ uint32_t _GetPrefix24(const uint8_t* p) {
    return (uint32_t(p[0]) << 16) | (uint32_t(p[1]) << 8) | uint32_t(p[2]);
}
__device__ int _BinarySearch20Indexed(const uint8_t* buffer, const uint64_t* prefixIndex, const uint8_t* target) {
    uint32_t p = _GetPrefix24(target);
    uint64_t lo = prefixIndex[p], hi = prefixIndex[p + 1];
    if (lo >= hi) return -1;
    while (lo < hi) {
        uint64_t mid = (lo + hi) / 2;
        const uint8_t* addr = buffer + mid * 20;
        bool equal = true, less = false;
        for(int i = 0; i < 20; i++) { if(addr[i] != target[i]) { less = (addr[i] < target[i]); equal = false; break; } }
        if(equal) return (int)mid;
        else if(less) lo = mid + 1; else hi = mid;
    }
    return -1;
}

// ============================================================
// GPU: _PointMultiSecp256k1 – IDENTYCZNY jak w main.cu
// ============================================================
__device__ void _PointMultiSecp256k1(
    uint64_t *qx,
    uint64_t *qy,
    uint16_t *privKey,
    uint8_t *gTableX,
    uint8_t *gTableY
) {
    int chunk = 0;
    uint64_t qz[5] = {1,0,0,0,0};
    for (; chunk < NUM_GTABLE_CHUNK; chunk++) {
        if (privKey[chunk] > 0) {
            int index = (CHUNK_FIRST_ELEMENT[chunk] + (privKey[chunk] - 1)) * POINT_SIZE;
            memcpy(qx, gTableX + index, POINT_SIZE);
            memcpy(qy, gTableY + index, POINT_SIZE);
            chunk++;
            break;
        }
    }
    for (; chunk < NUM_GTABLE_CHUNK; chunk++) {
        if (privKey[chunk] > 0) {
            uint64_t gx[4], gy[4];
            int index = (CHUNK_FIRST_ELEMENT[chunk] + (privKey[chunk] - 1)) * POINT_SIZE;
            memcpy(gx, gTableX + index, POINT_SIZE);
            memcpy(gy, gTableY + index, POINT_SIZE);
            _PointAddSecp256k1(qx, qy, qz, gx, gy);
        }
    }
    _ModInv(qz);
    _ModMult(qx, qz);
    _ModMult(qy, qz);
}

// ============================================================
// KERNEL BRAINWALLET (z zapisem indeksu frazy)
// ============================================================
__global__ void brainwallet_kernel(
    const char* __restrict__ phrases,
    const uint16_t* __restrict__ lengths,
    uint64_t num_phrases,
    const uint8_t* __restrict__ hash_data,
    uint64_t hash_count,
    const uint64_t* __restrict__ prefix_index,
    uint8_t* __restrict__ gTableX,
    uint8_t* __restrict__ gTableY,
    unsigned char* __restrict__ found_keys,
    unsigned char* __restrict__ found_type,
    unsigned int* __restrict__ found_index,   // NOWY bufor na indeksy fraz
    unsigned int* __restrict__ found_count,
    unsigned long long* __restrict__ progress_ptr
) {
    uint64_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx >= num_phrases) return;

    const char* phrase = phrases + idx * MAX_PASS_LEN;
    uint16_t len = lengths[idx];

    // 1. SHA256 frazy -> klucz prywatny (32 bajty)
    uint8_t priv_key[32];
    _SHA256Brainwallet((const uint8_t*)phrase, len, priv_key);

    // Sprawdź czy klucz nie jest zerem
    bool isZero = true;
    for(int i=0;i<32;i++) if(priv_key[i]!=0){ isZero=false; break; }
    if(isZero) { atomicAdd(progress_ptr,1); return; }

    // 2. OPTYMALIZACJA: szybkie sprawdzenie prefiksu 24-bitowego
    // Jeśli prefiks nie występuje w bazie, pomijamy EC
    if (prefix_index != nullptr) {
        uint32_t prefix = (priv_key[0] << 16) | (priv_key[1] << 8) | priv_key[2];
        uint64_t lo = prefix_index[prefix];
        uint64_t hi = prefix_index[prefix + 1];
        if (lo == hi) {
            atomicAdd(progress_ptr, 1);
            return;
        }
    }

    // 3. Przygotuj 16-bitowe chunki dla GTable (dokładnie jak w main.cu)
    uint16_t priv_chunks[16] = {0};
    for(int i=0; i<16; i++) {
        priv_chunks[15 - i] = (priv_key[i*2] << 8) | priv_key[i*2 + 1];
    }

    // 4. Oblicz punkt publiczny (qx, qy) – LSB-first
    uint64_t qx[4], qy[4];
    // Sprawdź czy priv == 1 (hardcoded dla oszczędności)
    bool isPrivOne = true;
    for(int i=0;i<31;i++) if(priv_key[i]!=0){ isPrivOne=false; break; }
    if(priv_key[31]!=1) isPrivOne=false;
    if(isPrivOne) {
        // G
        qx[0] = 0x59F2815B16F81798ULL;
        qx[1] = 0x029BFCDB2DCE28D9ULL;
        qx[2] = 0x55A06295CE870B07ULL;
        qx[3] = 0x79BE667EF9DCBBACULL;
        qy[0] = 0x9C47D08FFB10D4B8ULL;
        qy[1] = 0xFD17B448A6855419ULL;
        qy[2] = 0x5DA4FBFC0E1108A8ULL;
        qy[3] = 0x483ADA7726A3C465ULL;
    } else {
        _PointMultiSecp256k1(qx, qy, priv_chunks, gTableX, gTableY);
    }

    // 5. Oblicz hash160 dla compressed i uncompressed
    uint8_t isOdd = (uint8_t)(qy[0] & 1);
    uint8_t hash_comp[20];
    _GetHash160Comp(qx, isOdd, hash_comp);

    uint8_t hash_unc[20];
    _GetHash160(qx, qy, hash_unc);

    // 6. Szukaj w bazie (z indeksem lub bez)
    int pos_comp = (prefix_index != nullptr) ?
        _BinarySearch20Indexed(hash_data, prefix_index, hash_comp) :
        _BinarySearch20(hash_data, hash_count, hash_comp);

    if(pos_comp >= 0) {
        unsigned int fidx = atomicAdd(found_count, 1u);
        if(fidx < MAX_FOUND_KEYS) {
            for(int j=0;j<32;j++) found_keys[fidx*32 + j] = priv_key[j];
            found_type[fidx] = 0; // compressed
            found_index[fidx] = (unsigned int)idx; // zapisz indeks frazy
        }
    }

    int pos_unc = (prefix_index != nullptr) ?
        _BinarySearch20Indexed(hash_data, prefix_index, hash_unc) :
        _BinarySearch20(hash_data, hash_count, hash_unc);

    if(pos_unc >= 0) {
        unsigned int fidx = atomicAdd(found_count, 1u);
        if(fidx < MAX_FOUND_KEYS) {
            for(int j=0;j<32;j++) found_keys[fidx*32 + j] = priv_key[j];
            found_type[fidx] = 1; // uncompressed
            found_index[fidx] = (unsigned int)idx; // zapisz indeks frazy
        }
    }

    atomicAdd(progress_ptr, 1);
}

// ============================================================
// KLASA SKANERA (batch processing)
// ============================================================
class FastScan {
private:
    uint8_t* gpu_hash_data = nullptr;
    uint8_t* gpu_gTableX = nullptr;
    uint8_t* gpu_gTableY = nullptr;
    unsigned char* gpu_found = nullptr;
    unsigned char* gpu_found_type = nullptr;
    unsigned int* gpu_found_index = nullptr;   // NOWE
    unsigned int* gpu_found_count = nullptr;
    uint64_t* gpu_prefix_index = nullptr;
    unsigned long long* progress_pinned = nullptr;
    uint64_t hash_count = 0;
    MMapFile hash_mmap;
    vector<uint8_t> cpu_gTableX, cpu_gTableY;
    vector<unsigned char> cpu_found, cpu_found_type;
    vector<unsigned int> cpu_found_index;      // NOWE
public:
    ~FastScan() {
        if(gpu_hash_data) cudaFree(gpu_hash_data);
        if(gpu_gTableX) cudaFree(gpu_gTableX);
        if(gpu_gTableY) cudaFree(gpu_gTableY);
        if(gpu_found) cudaFree(gpu_found);
        if(gpu_found_type) cudaFree(gpu_found_type);
        if(gpu_found_index) cudaFree(gpu_found_index);
        if(gpu_found_count) cudaFree(gpu_found_count);
        if(gpu_prefix_index) cudaFree(gpu_prefix_index);
        if(progress_pinned) cudaFreeHost(progress_pinned);
    }

    bool init(const char* db_path) {
        cout << "📂 Mapowanie (mmap) pliku adresów: " << db_path << "\n";
        try {
            hash_mmap.open_file(db_path);
        } catch(const std::exception& e) {
            cerr << "❌ Błąd mmap: " << e.what() << "\n";
            return false;
        }
        hash_count = hash_mmap.length() / 20;
        cout << "📊 Hash-y: " << hash_count << "\n";
        cout << "📊 Rozmiar pliku: " << (hash_mmap.length() / (1024*1024*1024)) << " GB (mmap)\n";

        cout << "📂 Ładowanie GTable...\n";
        cpu_gTableX = loadFile("gtableX.bin");
        cpu_gTableY = loadFile("gtableY.bin");
        cout << "   gtableX: " << cpu_gTableX.size() / (1024*1024) << " MB\n";
        cout << "   gtableY: " << cpu_gTableY.size() / (1024*1024) << " MB\n";

        cout << "\n🖥️  Inicjalizacja GPU...\n";
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, 0);
        cout << "   GPU: " << prop.name << "\n";
        cout << "   VRAM: " << prop.totalGlobalMem / (1024*1024*1024) << " GB\n";

        cout << "📦 Kopiowanie hash-y na GPU...\n";
        cudaMalloc(&gpu_hash_data, hash_mmap.length());
        cudaMemcpy(gpu_hash_data, hash_mmap.ptr(), hash_mmap.length(), cudaMemcpyHostToDevice);

        cout << "📦 Kopiowanie GTable na GPU...\n";
        cudaMalloc(&gpu_gTableX, cpu_gTableX.size());
        cudaMemcpy(gpu_gTableX, cpu_gTableX.data(), cpu_gTableX.size(), cudaMemcpyHostToDevice);
        cudaMalloc(&gpu_gTableY, cpu_gTableY.size());
        cudaMemcpy(gpu_gTableY, cpu_gTableY.data(), cpu_gTableY.size(), cudaMemcpyHostToDevice);

        cudaMalloc(&gpu_found, MAX_FOUND_KEYS * 32);
        cudaMalloc(&gpu_found_type, MAX_FOUND_KEYS);
        cudaMalloc(&gpu_found_index, MAX_FOUND_KEYS * sizeof(unsigned int)); // NOWE
        cudaMalloc(&gpu_found_count, sizeof(unsigned int));
        cudaMemset(gpu_found_count, 0, sizeof(unsigned int));
        cpu_found.resize(MAX_FOUND_KEYS * 32);
        cpu_found_type.resize(MAX_FOUND_KEYS);
        cpu_found_index.resize(MAX_FOUND_KEYS); // NOWE

        cudaHostAlloc((void**)&progress_pinned, sizeof(unsigned long long), cudaHostAllocMapped);
        *progress_pinned = 0;

        // Indeks 24-bitowy – dokładnie taki sam jak w main.cu
        cout << "📦 Budowanie indeksu 24-bit...\n";
        vector<uint64_t> cpu_prefix_index(16777217, 0);
        {
            const uint8_t* base = hash_mmap.ptr();
            uint64_t count = hash_count;
            uint64_t pos = 0, buckets = 0;
            while(pos < count) {
                uint32_t p = (uint32_t(base[pos*20]) << 16) | (uint32_t(base[pos*20+1]) << 8) | base[pos*20+2];
                cpu_prefix_index[p] = pos;
                uint64_t lo = pos, hi = count;
                while(lo + 1 < hi) {
                    uint64_t mid = (lo + hi) / 2;
                    uint32_t mp = (uint32_t(base[mid*20]) << 16) | (uint32_t(base[mid*20+1]) << 8) | base[mid*20+2];
                    if(mp <= p) lo = mid;
                    else hi = mid;
                }
                cpu_prefix_index[p + 1] = lo + 1;
                pos = lo + 1;
                buckets++;
                if(buckets % 200000 == 0) {
                    cout << "\r   Przetworzono: " << pos << "/" << count << " rekordów | Znaleziono: " << buckets << " prefiksów" << flush;
                }
            }
            uint64_t last_start = 0, last_end = count;
            for(int64_t i = 16777215; i >= 0; i--) {
                if(cpu_prefix_index[i] != 0 || i == 0) {
                    last_start = cpu_prefix_index[i];
                    last_end = cpu_prefix_index[i + 1];
                } else {
                    cpu_prefix_index[i] = last_start;
                    cpu_prefix_index[i + 1] = last_end;
                }
            }
            cout << "\n✅ Indeks: " << buckets << "/16777216 prefiksów używanych\n";
        }

        size_t idxBytes = cpu_prefix_index.size() * sizeof(uint64_t);
        cudaError_t allocErr = cudaMalloc(&gpu_prefix_index, idxBytes);
        if(allocErr != cudaSuccess) {
            cerr << "⚠️  Nie udalo sie zaalokowac indeksu na GPU (" << idxBytes / (1024*1024)
                 << " MB): " << cudaGetErrorString(allocErr)
                 << " - kontynuuje BEZ indeksu (wolniejszy fallback)\n";
            gpu_prefix_index = nullptr;
        } else {
            cudaMemcpy(gpu_prefix_index, cpu_prefix_index.data(), idxBytes, cudaMemcpyHostToDevice);
            cout << "✅ Indeks skopiowany na GPU (" << idxBytes / (1024*1024) << " MB)\n";
        }

        cout << "✅ GPU gotowe!\n";
        return true;
    }

    // Przetwarzanie batchowe
    void processBatch(const vector<string>& batch, uint64_t batch_num, uint64_t total_batches, ofstream& outfile) {
        uint64_t count = batch.size();
        if(count == 0) return;

        // Przygotowanie danych batcha
        char* h_phrases = new char[count * MAX_PASS_LEN]();
        uint16_t* h_lengths = new uint16_t[count]();
        for(uint64_t i=0; i<count; i++) {
            uint16_t len = min((size_t)batch[i].length(), (size_t)(MAX_PASS_LEN - 1));
            memcpy(h_phrases + i * MAX_PASS_LEN, batch[i].c_str(), len);
            h_lengths[i] = len;
        }

        char* d_phrases;
        uint16_t* d_lengths;
        cudaMalloc(&d_phrases, count * MAX_PASS_LEN);
        cudaMalloc(&d_lengths, count * sizeof(uint16_t));
        cudaMemcpy(d_phrases, h_phrases, count * MAX_PASS_LEN, cudaMemcpyHostToDevice);
        cudaMemcpy(d_lengths, h_lengths, count * sizeof(uint16_t), cudaMemcpyHostToDevice);

        cudaMemset(gpu_found_count, 0, sizeof(unsigned int));
        *progress_pinned = 0;

        int blocks = (count + THREADS - 1) / THREADS;
        auto start = chrono::steady_clock::now();

        brainwallet_kernel<<<blocks, THREADS>>>(
            d_phrases,
            d_lengths,
            count,
            gpu_hash_data,
            hash_count,
            gpu_prefix_index,
            gpu_gTableX,
            gpu_gTableY,
            gpu_found,
            gpu_found_type,
            gpu_found_index,
            gpu_found_count,
            progress_pinned
        );

        cudaDeviceSynchronize();
        auto end = chrono::steady_clock::now();
        double elapsed = chrono::duration<double>(end - start).count();

        unsigned int found = 0;
        cudaMemcpy(&found, gpu_found_count, sizeof(unsigned int), cudaMemcpyDeviceToHost);

        if(found > 0) {
            if(found > MAX_FOUND_KEYS) found = MAX_FOUND_KEYS;
            cudaMemcpy(cpu_found.data(), gpu_found, found * 32, cudaMemcpyDeviceToHost);
            cudaMemcpy(cpu_found_type.data(), gpu_found_type, found, cudaMemcpyDeviceToHost);
            cudaMemcpy(cpu_found_index.data(), gpu_found_index, found * sizeof(unsigned int), cudaMemcpyDeviceToHost);

            for(unsigned int i=0; i<found; i++) {
                unsigned char* key = cpu_found.data() + i * 32;
                bool isUncompressed = (cpu_found_type[i] != 0);
                string addr = isUncompressed ? keyToAddressUncompressed(key) : keyToAddressCompressed(key);
                const char* typeLabel = isUncompressed ? "UNCOMPRESSED" : "COMPRESSED";

                // Pobierz frazę z batcha
                uint32_t idx = cpu_found_index[i];
                string phrase = (idx < batch.size()) ? batch[idx] : "?";

                cout << "🎯 ZNALEZIONO: " << phrase << "\n";
                cout << "   KEY: ";
                for(int j=0; j<32; j++) cout << hex << setw(2) << setfill('0') << (int)key[j];
                cout << dec << "\n";
                cout << "   TYP: " << typeLabel << "\n";
                cout << "   ADDR: " << addr << "\n\n";

                outfile << "FRAZA: " << phrase << "\n";
                outfile << "KEY: ";
                for(int j=0; j<32; j++) outfile << hex << setw(2) << setfill('0') << (int)key[j];
                outfile << dec << "\n";
                outfile << "TYP: " << typeLabel << "\n";
                outfile << "ADDR: " << addr << "\n---\n";
                outfile.flush();
            }
        }

        double speed = count / elapsed / 1e6;
        cout << "   Batch " << batch_num+1 << "/" << total_batches
             << " | " << count << " fraz | " << fixed << setprecision(2) << elapsed << " s | "
             << speed << " MH/s | found: " << found << "\n";

        cudaFree(d_phrases);
        cudaFree(d_lengths);
        delete[] h_phrases;
        delete[] h_lengths;
    }
};

// ============================================================
// MAIN
// ============================================================
int main(int argc, char* argv[]) {
    if(argc < 3) {
        cout << "================================================================\n";
        cout << "🧠 BRAINWALLET GPU CRACKER (BATCH MODE + FRAZA)\n";
        cout << "================================================================\n\n";
        cout << "Użycie: " << argv[0] << " frazy.txt adresy.bin\n";
        cout << "   lub: cat frazy.txt | " << argv[0] << " - adresy.bin\n\n";
        cout << "Plik frazy.txt zawiera jedną frazę na linię.\n";
        cout << "Program przetwarza w partiach po " << BATCH_SIZE << " fraz, minimalizując zużycie RAM.\n";
        return 1;
    }

    const char* phrases_path = argv[1];
    const char* db_path = argv[2];

    FastScan scanner;
    if(!scanner.init(db_path)) return 1;

    ifstream* infile = nullptr;
    bool use_stdin = (string(phrases_path) == "-");
    if(use_stdin) {
        // stdin już jest otwarty
    } else {
        infile = new ifstream(phrases_path);
        if(!infile->is_open()) {
            cerr << "❌ Nie można otworzyć pliku z frazami: " << phrases_path << "\n";
            return 1;
        }
    }

    ofstream outfile("found_brainwallet.txt", ios::app);

    vector<string> batch;
    batch.reserve(BATCH_SIZE);
    uint64_t total_processed = 0;
    uint64_t batch_num = 0;

    string line;
    auto read_line = [&]() -> bool {
        if(use_stdin) {
            if(!getline(cin, line)) return false;
            return true;
        } else {
            return (bool)getline(*infile, line);
        }
    };

    while(read_line()) {
        if(line.empty()) continue;
        batch.push_back(line);
        if(batch.size() >= BATCH_SIZE) {
            scanner.processBatch(batch, batch_num, 0, outfile);
            total_processed += batch.size();
            batch.clear();
            batch_num++;
        }
    }

    if(!batch.empty()) {
        scanner.processBatch(batch, batch_num, 0, outfile);
        total_processed += batch.size();
    }

    cout << "\n✅ Przetworzono lącznie " << total_processed << " fraz.\n";
    cout << "📁 Wyniki zapisano w found_brainwallet.txt\n";

    if(infile) delete infile;
    outfile.close();
    return 0;
}