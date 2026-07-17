// ============================================================
// GENERATOR SŁÓW/FRAZ v4.0 - POPRAWIONA WERSJA
// ============================================================

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <chrono>
#include <thread>
#include <mutex>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <algorithm>
#include <random>
#include <signal.h>
#include <unistd.h>

using namespace std;

// ============================================================
// KONFIGURACJA
// ============================================================
#define FLUSH_EVERY 10000
#define MAX_WORDS 1000000
#define MAX_PHRASE_LEN 256
#define STATS_INTERVAL 5

// ============================================================
// STRUKTURY
// ============================================================
struct GeneratorConfig {
    string input_file = "words.txt";
    string output_file = "";
    int words_count = 2;
    int min_len = 0;
    int max_len = 100;
    bool use_numbers = false;
    bool use_random_number = false;
    int num_min_len = 8;
    int num_max_len = 20;
    bool use_special = false;
    bool use_random_special = false;
    bool no_space = false;
    bool random_order = false;
    bool unique_only = false;
    bool case_variations = false;
    bool leet_speak = false;
    uint64_t max_combinations = 0;
    int num_threads = 30;
    char separator = ' ';
    bool append_newline = true;
    int min_random_words = 3;
    int max_random_words = 8;
};

struct Stats {
    atomic<uint64_t> generated{0};
    atomic<uint64_t> errors{0};
    chrono::steady_clock::time_point start;
    double speed;
};

// Mutex chroniący wspólny strumień wyjściowy (cout) przed przeplataniem
// linii z różnych wątków roboczych.
static mutex g_output_mutex;

// Wypisuje zawartość bufora do cout w sposób bezpieczny wątkowo i czyści bufor.
static void flush_buffer(string& buffer) {
    if (buffer.empty()) return;
    lock_guard<mutex> lk(g_output_mutex);
    cout << buffer;
    cout.flush();
    buffer.clear();
}

// ============================================================
// FUNKCJE POMOCNICZE
// ============================================================
vector<string> load_words(const string& filename) {
    vector<string> words;
    ifstream in(filename);
    if (!in) {
        cerr << "❌ Nie można otworzyć: " << filename << "\n";
        return words;
    }
    
    string line;
    while (getline(in, line)) {
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        if (!line.empty()) {
            words.push_back(line);
        }
    }
    return words;
}

string to_lower(const string& s) {
    string result = s;
    transform(result.begin(), result.end(), result.begin(), ::tolower);
    return result;
}

string to_upper(const string& s) {
    string result = s;
    transform(result.begin(), result.end(), result.begin(), ::toupper);
    return result;
}

string capitalize(const string& s) {
    if (s.empty()) return s;
    string result = s;
    result[0] = toupper(result[0]);
    return result;
}

string leet_speak(const string& s) {
    string result = s;
    for (char& c : result) {
        switch (tolower(c)) {
            case 'a': c = '4'; break;
            case 'e': c = '3'; break;
            case 'i': c = '1'; break;
            case 'o': c = '0'; break;
            case 's': c = '5'; break;
            case 't': c = '7'; break;
            case 'b': c = '8'; break;
            case 'g': c = '9'; break;
            case 'z': c = '2'; break;
        }
    }
    return result;
}

// ============================================================
// FUNKCJE POMOCNICZE - JEDNA DEFINICJA KAŻDEJ
// ============================================================

// Generator liczb losowych per-wątek (szybki i bezpieczny wątkowo)
static mt19937_64& rng() {
    static thread_local mt19937_64 gen(
        random_device{}() ^
        (uint64_t)hash<thread::id>{}(this_thread::get_id())
    );
    return gen;
}

// Buduje losowy ciąg cyfr o zadanej długości (bez przepełnień int/uint64).
static string random_digits(int len) {
    if (len < 1) len = 1;
    string num_str;
    num_str.reserve(len);
    // Pierwsza cyfra 1-9, kolejne 0-9 (żeby długość była zachowana).
    uniform_int_distribution<int> first(1, 9);
    uniform_int_distribution<int> rest(0, 9);
    num_str += char('0' + first(rng()));
    for (int i = 1; i < len; i++) {
        num_str += char('0' + rest(rng()));
    }
    return num_str;
}

// "Stałe" liczby - deterministyczne dla danego słowa (obliczane z jego treści).
string add_numbers(const string& s, int min_len, int max_len) {
    if (min_len < 1) min_len = 1;
    if (max_len < min_len) max_len = min_len;
    // Deterministyczna długość i wartość zależna od słowa.
    uint64_t h = 1469598103934665603ULL; // FNV-1a
    for (unsigned char c : s) { h ^= c; h *= 1099511628211ULL; }
    int len = min_len + (int)(h % (uint64_t)(max_len - min_len + 1));
    string num_str;
    num_str.reserve(len);
    num_str += char('1' + (int)(h % 9));
    for (int i = 1; i < len; i++) {
        h *= 1099511628211ULL;
        num_str += char('0' + (int)(h % 10));
    }
    return s + num_str;
}

string add_random_number(const string& s, int min_len, int max_len) {
    if (min_len < 1) min_len = 1;
    if (max_len < min_len) max_len = min_len;
    int len = uniform_int_distribution<int>(min_len, max_len)(rng());
    return s + random_digits(len);
}

string add_random_special_char(const string& s) {
    static const string specials = "!@#$%^&*()_+-=[]{}|;:,.<>?";
    char special = specials[uniform_int_distribution<size_t>(0, specials.size() - 1)(rng())];
    if (uniform_int_distribution<int>(0, 1)(rng()) == 0) {
        return special + s;
    } else {
        return s + special;
    }
}

string add_special_chars(const string& s) {
    static const string specials = "!@#$%^&*()_+-=[]{}|;:,.<>?";
    // "Stałe" znaki - deterministyczne dla danego słowa.
    uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : s) { h ^= c; h *= 1099511628211ULL; }
    char special = specials[h % specials.size()];
    if ((h >> 8) % 2 == 0) {
        return special + s;
    } else {
        return s + special;
    }
}

// ============================================================
// GENEROWANIE KOMBINACJI 2 SŁÓW
// ============================================================
void generate_combinations_2words(const vector<string>& words, 
                                   size_t start_i, size_t end_i,
                                   const GeneratorConfig& config,
                                   Stats& stats) {
    string buffer;
    buffer.reserve(1024 * 1024);
    uint64_t flush_counter = 0;
    size_t n = words.size();
    
    for (size_t i = start_i; i < end_i && (config.max_combinations == 0 || stats.generated < config.max_combinations); i++) {
        for (size_t j = 0; j < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); j++) {
            
            string phrase;
            if (config.no_space) {
                phrase = words[i] + words[j];
            } else {
                phrase = words[i] + config.separator + words[j];
            }
            
            vector<string> variants;
            variants.push_back(phrase);
            
            if (config.case_variations) {
                variants.push_back(to_lower(phrase));
                variants.push_back(to_upper(phrase));
                variants.push_back(capitalize(phrase));
            }
            
            if (config.leet_speak) {
                variants.push_back(leet_speak(phrase));
            }
            
            for (const string& var : variants) {
                string final_phrase = var;
                
                if (config.use_random_number) {
                    final_phrase = add_random_number(final_phrase, config.num_min_len, config.num_max_len);
                }
                
                if (config.use_random_special) {
                    final_phrase = add_random_special_char(final_phrase);
                }
                
                if (config.use_numbers && !config.use_random_number) {
                    final_phrase = add_numbers(final_phrase, config.num_min_len, config.num_max_len);
                }
                
                if (config.use_special && !config.use_random_special) {
                    final_phrase = add_special_chars(final_phrase);
                }
                
                buffer += final_phrase;
                if (config.append_newline) buffer += '\n';
                stats.generated++;
                flush_counter++;
                
                if (flush_counter >= FLUSH_EVERY) {
                    flush_buffer(buffer);
                    flush_counter = 0;
                }
            }
        }
    }
    
    if (!buffer.empty()) {
        flush_buffer(buffer);
    }
    
}

// ============================================================
// GENEROWANIE KOMBINACJI 3 SŁÓW
// ============================================================
void generate_combinations_3words(const vector<string>& words,
                                   size_t start_i, size_t end_i,
                                   const GeneratorConfig& config,
                                   Stats& stats) {
    string buffer;
    buffer.reserve(1024 * 1024);
    uint64_t flush_counter = 0;
    size_t n = words.size();
    
    for (size_t i = start_i; i < end_i && (config.max_combinations == 0 || stats.generated < config.max_combinations); i++) {
        for (size_t j = 0; j < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); j++) {
            for (size_t k = 0; k < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); k++) {
                
                string phrase;
                if (config.no_space) {
                    phrase = words[i] + words[j] + words[k];
                } else {
                    phrase = words[i] + config.separator + words[j] + config.separator + words[k];
                }
                
                vector<string> variants;
                variants.push_back(phrase);
                
                if (config.case_variations) {
                    variants.push_back(to_lower(phrase));
                    variants.push_back(to_upper(phrase));
                    variants.push_back(capitalize(phrase));
                }
                
                if (config.leet_speak) {
                    variants.push_back(leet_speak(phrase));
                }
                
                for (const string& var : variants) {
                    string final_phrase = var;
                    
                    if (config.use_random_number) {
                        final_phrase = add_random_number(final_phrase, config.num_min_len, config.num_max_len);
                    }
                    
                    if (config.use_random_special) {
                        final_phrase = add_random_special_char(final_phrase);
                    }
                    
                    if (config.use_numbers && !config.use_random_number) {
                        final_phrase = add_numbers(final_phrase, config.num_min_len, config.num_max_len);
                    }
                    
                    if (config.use_special && !config.use_random_special) {
                        final_phrase = add_special_chars(final_phrase);
                    }
                    
                    buffer += final_phrase;
                    if (config.append_newline) buffer += '\n';
                    stats.generated++;
                    flush_counter++;
                    
                    if (flush_counter >= FLUSH_EVERY) {
                        flush_buffer(buffer);
                    flush_counter = 0;
                    }
                }
            }
        }
    }
    
    if (!buffer.empty()) {
        flush_buffer(buffer);
    }
    
}

// ============================================================
// GENEROWANIE KOMBINACJI 4 SŁÓW
// ============================================================
void generate_combinations_4words(const vector<string>& words,
                                   size_t start_i, size_t end_i,
                                   const GeneratorConfig& config,
                                   Stats& stats) {
    string buffer;
    buffer.reserve(1024 * 1024);
    uint64_t flush_counter = 0;
    size_t n = words.size();
    
    for (size_t i = start_i; i < end_i && (config.max_combinations == 0 || stats.generated < config.max_combinations); i++) {
        for (size_t j = 0; j < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); j++) {
            for (size_t k = 0; k < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); k++) {
                for (size_t l = 0; l < n && (config.max_combinations == 0 || stats.generated < config.max_combinations); l++) {
                    
                    string phrase;
                    if (config.no_space) {
                        phrase = words[i] + words[j] + words[k] + words[l];
                    } else {
                        phrase = words[i] + config.separator + words[j] + config.separator + words[k] + config.separator + words[l];
                    }
                    
                    vector<string> variants;
                    variants.push_back(phrase);
                    
                    if (config.case_variations) {
                        variants.push_back(to_lower(phrase));
                        variants.push_back(to_upper(phrase));
                        variants.push_back(capitalize(phrase));
                    }
                    
                    if (config.leet_speak) {
                        variants.push_back(leet_speak(phrase));
                    }
                    
                    for (const string& var : variants) {
                        string final_phrase = var;
                        
                        if (config.use_random_number) {
                            final_phrase = add_random_number(final_phrase, config.num_min_len, config.num_max_len);
                        }
                        
                        if (config.use_random_special) {
                            final_phrase = add_random_special_char(final_phrase);
                        }
                        
                        if (config.use_numbers && !config.use_random_number) {
                            final_phrase = add_numbers(final_phrase, config.num_min_len, config.num_max_len);
                        }
                        
                        if (config.use_special && !config.use_random_special) {
                            final_phrase = add_special_chars(final_phrase);
                        }
                        
                        buffer += final_phrase;
                        if (config.append_newline) buffer += '\n';
                        stats.generated++;
                        flush_counter++;
                        
                        if (flush_counter >= FLUSH_EVERY) {
                            flush_buffer(buffer);
                    flush_counter = 0;
                        }
                    }
                }
            }
        }
    }
    
    if (!buffer.empty()) {
        flush_buffer(buffer);
    }
    
}

// ============================================================
// GENEROWANIE LOSOWYCH FRAZ
// ============================================================
void generate_random_phrases(const vector<string>& words, 
                              uint64_t count,
                              const GeneratorConfig& config,
                              Stats& stats) {
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> word_dist(0, words.size() - 1);
    uniform_int_distribution<> word_count_dist(config.min_random_words, config.max_random_words);
    
    string buffer;
    buffer.reserve(1024 * 1024);
    uint64_t flush_counter = 0;
    
    for (uint64_t i = 0; i < count && (config.max_combinations == 0 || stats.generated < config.max_combinations); i++) {
        int num_words = word_count_dist(gen);
        
        string phrase;
        for (int w = 0; w < num_words; w++) {
            if (w > 0) {
                if (config.no_space) {
                    // bez spacji
                } else {
                    phrase += config.separator;
                }
            }
            phrase += words[word_dist(gen)];
        }
        
        vector<string> variants;
        variants.push_back(phrase);
        
        if (config.case_variations) {
            variants.push_back(to_lower(phrase));
            variants.push_back(to_upper(phrase));
            variants.push_back(capitalize(phrase));
        }
        
        if (config.leet_speak) {
            variants.push_back(leet_speak(phrase));
        }
        
        for (const string& var : variants) {
            string final_phrase = var;
            
            if (config.use_random_number) {
                final_phrase = add_random_number(final_phrase, config.num_min_len, config.num_max_len);
            }
            
            if (config.use_random_special) {
                final_phrase = add_random_special_char(final_phrase);
            }
            
            if (config.use_numbers && !config.use_random_number) {
                final_phrase = add_numbers(final_phrase, config.num_min_len, config.num_max_len);
            }
            
            if (config.use_special && !config.use_random_special) {
                final_phrase = add_special_chars(final_phrase);
            }
            
            buffer += final_phrase;
            if (config.append_newline) buffer += '\n';
            stats.generated++;
            flush_counter++;
            
            if (flush_counter >= FLUSH_EVERY) {
                flush_buffer(buffer);
                    flush_counter = 0;
            }
        }
    }
    
    if (!buffer.empty()) {
        flush_buffer(buffer);
    }
}

// ============================================================
// GENEROWANIE LICZB
// ============================================================
void generate_numbers(int min_len, int max_len, const GeneratorConfig& config, Stats& stats) {
    string buffer;
    buffer.reserve(1024 * 1024);
    uint64_t flush_counter = 0;
    
    uint64_t start_num = pow(10, min_len - 1);
    uint64_t end_num = pow(10, max_len) - 1;
    
    for (uint64_t num = start_num; num <= end_num && (config.max_combinations == 0 || stats.generated < config.max_combinations); num++) {
        string num_str = to_string(num);
        buffer += num_str;
        if (config.append_newline) buffer += '\n';
        stats.generated++;
        flush_counter++;
        
        if (flush_counter >= FLUSH_EVERY) {
            flush_buffer(buffer);
                    flush_counter = 0;
        }
    }
    
    if (!buffer.empty()) {
        flush_buffer(buffer);
    }
}

// ============================================================
// WYŚWIETLANIE STATYSTYK
// ============================================================
void display_stats(const Stats& stats) {
    auto now = chrono::steady_clock::now();
    double elapsed = chrono::duration<double>(now - stats.start).count();
    
    if (elapsed > 0) {
        double speed = stats.generated / elapsed;
        cerr << "\r📊 Wygenerowano: " << stats.generated 
             << " | Prędkość: " << fixed << setprecision(0) << speed << " fraz/s"
             << " | Czas: " << fixed << setprecision(1) << elapsed << "s"
             << flush;
    }
}

// ============================================================
// OBSŁUGA SYGNAŁÓW
// ============================================================
volatile sig_atomic_t stop_flag = 0;

void signal_handler(int sig) {
    stop_flag = 1;
    cerr << "\n⚠️ Otrzymano sygnał zatrzymania. Kończenie...\n";
}

// ============================================================
// MAIN
// ============================================================
int main(int argc, char* argv[]) {
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    cerr << "================================================================\n";
    cerr << "🔤 GENERATOR SŁÓW/FRAZ v4.0\n";
    cerr << "================================================================\n\n";
    
    GeneratorConfig config;
    Stats stats;
    stats.start = chrono::steady_clock::now();
    
    string mode = "words";
    string input_file = "words.txt";
    string output_file = "";
    uint64_t random_count = 0;
    
    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            cout << "Użycie:\n";
            cout << "  ./generator [tryb] [opcje]\n\n";
            cout << "Tryby:\n";
            cout << "  words           - kombinacje słów (domyślnie)\n";
            cout << "  numbers         - generuj liczby\n";
            cout << "  random          - losowe frazy\n";
            cout << "\nOpcje:\n";
            cout << "  -f <plik>       - plik ze słowami\n";
            cout << "  -o <plik>       - zapisz do pliku\n";
            cout << "  -w <2/3/4>      - liczba słów w frazie (domyślnie: 2)\n";
            cout << "  -n              - dodawaj liczby (stałe)\n";
            cout << "  -randnum        - dodawaj LOSOWE liczby (8-20 cyfr)\n";
            cout << "  -s              - dodawaj znaki specjalne (stałe)\n";
            cout << "  -randchar       - dodawaj LOSOWE znaki specjalne\n";
            cout << "  -nospace        - generuj BEZ spacji\n";
            cout << "  -l <min> <max>  - zakres długości liczby\n";
            cout << "  -c <liczba>     - limit kombinacji\n";
            cout << "  -t <liczba>     - liczba wątków\n";
            cout << "  -leet           - leet speak\n";
            cout << "  -case           - warianty wielkości liter\n";
            cout << "  -count <licz>   - liczba losowych fraz\n";
            cout << "  -range <min> <max> - zakres słów w losowej frazie\n";
            cout << "\nPrzykłady:\n";
            cout << "  ./generator words -f words.txt -w 2\n";
            cout << "  ./generator words -f words.txt -w 2 -nospace\n";
            cout << "  ./generator words -f words.txt -w 2 -randnum -randchar\n";
            cout << "  ./generator random -f words.txt -count 1000000 -range 3 8\n";
            return 0;
        } else if (arg == "-f" && i+1 < argc) {
            config.input_file = argv[++i];
        } else if (arg == "-o" && i+1 < argc) {
            config.output_file = argv[++i];
        } else if (arg == "-w" && i+1 < argc) {
            config.words_count = atoi(argv[++i]);
            if (config.words_count < 2) config.words_count = 2;
            if (config.words_count > 4) config.words_count = 4;
        } else if (arg == "-n") {
            config.use_numbers = true;
        } else if (arg == "-randnum") {
            config.use_random_number = true;
        } else if (arg == "-s") {
            config.use_special = true;
        } else if (arg == "-randchar") {
            config.use_random_special = true;
        } else if (arg == "-nospace") {
            config.no_space = true;
            config.separator = '\0';
        } else if (arg == "-l" && i+2 < argc) {
            config.num_min_len = atoi(argv[++i]);
            config.num_max_len = atoi(argv[++i]);
        } else if (arg == "-c" && i+1 < argc) {
            config.max_combinations = atoll(argv[++i]);
        } else if (arg == "-t" && i+1 < argc) {
            config.num_threads = atoi(argv[++i]);
        } else if (arg == "-leet") {
            config.leet_speak = true;
        } else if (arg == "-case") {
            config.case_variations = true;
        } else if (arg == "-count" && i+1 < argc) {
            random_count = atoll(argv[++i]);
        } else if (arg == "-range" && i+2 < argc) {
            config.min_random_words = atoi(argv[++i]);
            config.max_random_words = atoi(argv[++i]);
            if (config.min_random_words < 2) config.min_random_words = 2;
            if (config.max_random_words < config.min_random_words) 
                config.max_random_words = config.min_random_words;
        } else if (arg == "words") {
            mode = "words";
        } else if (arg == "numbers") {
            mode = "numbers";
        } else if (arg == "random") {
            mode = "random";
        }
    }
    
    vector<string> words;
    if (mode == "words" || mode == "random") {
        if (config.input_file == "-") {
            string line;
            while (getline(cin, line)) {
                if (!line.empty()) words.push_back(line);
            }
        } else {
            words = load_words(config.input_file);
        }
        
        if (words.empty()) {
            cerr << "❌ Brak słów do generowania!\n";
            return 1;
        }
        
        cerr << "📂 Wczytano " << words.size() << " słów\n";
    }
    
    streambuf* cout_buf = cout.rdbuf();
    ofstream out_file;
    
    if (!config.output_file.empty()) {
        out_file.open(config.output_file);
        if (!out_file) {
            cerr << "❌ Nie można otworzyć pliku wyjściowego: " << config.output_file << "\n";
            return 1;
        }
        cout.rdbuf(out_file.rdbuf());
    }
    
    cerr << "\n🚀 Rozpoczynanie generowania...\n";
    cerr << "   Tryb: " << mode << "\n";
    cerr << "   Liczba wątków: " << config.num_threads << "\n";
    cerr << "   Słowa: " << words.size() << "\n";
    cerr << "   Bez spacji: " << (config.no_space ? "TAK" : "NIE") << "\n";
    cerr << "   Losowa liczba: " << (config.use_random_number ? "TAK" : "NIE") << "\n";
    cerr << "   Losowy znak: " << (config.use_random_special ? "TAK" : "NIE") << "\n";
    if (config.max_combinations > 0) {
        cerr << "   Limit kombinacji: " << config.max_combinations << "\n";
    }
    cerr << "\n";
    
    try {
        if (mode == "numbers") {
            int min_len = config.num_min_len > 0 ? config.num_min_len : 8;
            int max_len = config.num_max_len > 0 ? config.num_max_len : 12;
            cerr << "🔢 Generowanie liczb (" << min_len << "-" << max_len << " cyfr)\n";
            generate_numbers(min_len, max_len, config, stats);
            
        } else if (mode == "random") {
            if (random_count == 0) {
                cerr << "❌ Brak liczby losowych fraz (użyj -count)\n";
                return 1;
            }
            cerr << "🎲 Generowanie " << random_count << " losowych fraz ("
                 << config.min_random_words << "-" << config.max_random_words << " słów)\n";
            generate_random_phrases(words, random_count, config, stats);
            
        } else {
            size_t n = words.size();
            uint64_t total = 1;
            for (int i = 0; i < config.words_count; i++) total *= n;
            
            if (config.max_combinations > 0 && config.max_combinations < total) {
                total = config.max_combinations;
            }
            
            cerr << "🧠 Generowanie kombinacji " << config.words_count << " słów\n";
            cerr << "   Łącznie: " << total << " kombinacji\n";
            
            int num_threads = min(config.num_threads, (int)n);
            size_t chunk_size = n / num_threads;
            
            vector<thread> threads;
            
            for (int t = 0; t < num_threads; t++) {
                size_t start_i = t * chunk_size;
                size_t end_i = (t == num_threads - 1) ? n : start_i + chunk_size;
                
                if (config.words_count == 2) {
                    threads.emplace_back(generate_combinations_2words,
                        ref(words), start_i, end_i,
                        ref(config), ref(stats));
                } else if (config.words_count == 3) {
                    threads.emplace_back(generate_combinations_3words,
                        ref(words), start_i, end_i,
                        ref(config), ref(stats));
                } else if (config.words_count == 4) {
                    threads.emplace_back(generate_combinations_4words,
                        ref(words), start_i, end_i,
                        ref(config), ref(stats));
                }
            }
            
            // Wątek monitorujący statystyki (działa aż wszystkie wątki robocze
            // się nie zakończą lub użytkownik nie przerwie działania).
            atomic<bool> workers_done{false};
            thread stats_thread([&]() {
                while (!workers_done && !stop_flag) {
                    for (int s = 0; s < STATS_INTERVAL * 10 && !workers_done && !stop_flag; s++) {
                        this_thread::sleep_for(chrono::milliseconds(100));
                    }
                    display_stats(stats);
                }
            });

            // Czekamy na zakończenie wątków roboczych.
            for (auto& th : threads) {
                if (th.joinable()) th.join();
            }

            workers_done = true;
            if (stats_thread.joinable()) stats_thread.join();
            display_stats(stats);
        }
        
    } catch (const exception& e) {
        cerr << "\n❌ Błąd: " << e.what() << "\n";
    }
    
    cout.flush();
    if (!config.output_file.empty()) {
        cout.rdbuf(cout_buf);
        out_file.close();
    }
    
    auto end = chrono::steady_clock::now();
    double elapsed = chrono::duration<double>(end - stats.start).count();
    double speed = elapsed > 0 ? stats.generated / elapsed : 0;
    
    cerr << "\n\n================================================================\n";
    cerr << "✅ GOTOWE!\n";
    cerr << "   Wygenerowano: " << stats.generated << " fraz\n";
    cerr << "   Czas: " << fixed << setprecision(1) << elapsed << "s\n";
    cerr << "   Średnia prędkość: " << fixed << setprecision(0) << speed << " fraz/s\n";
    if (!config.output_file.empty()) {
        cerr << "   Zapisano do: " << config.output_file << "\n";
    }
    cerr << "================================================================\n";
    
    return 0;
}