Tryb words - kombinacje słów
bash
# Podstawowe kombinacje 2 słów
./generator words -f words_unique.txt -w 2 | ./brainwallet_gpu - adresy_unique.bin

# Kombinacje 3 słów
./generator words -f words.txt -w 3 | ./brainwallet_gpu - adresy_unique.bin


# Kombinacje 4 słów
./generator words -f words.txt -w 4
Tryb numbers - liczby
bash
# Liczby od 8 do 12 cyfr
./generator numbers -l 8 12

# Liczby od 6 do 10 cyfr
./generator numbers -l 6 10

# Liczby od 10 do 15 cyfr
./generator numbers -l 10 15 | ./brainwallet_gpu - adresy_unique.bin

Tryb random - losowe frazy
bash
# 1 milion losowych fraz (domyślnie 3-8 słów)
./generator random -f words.txt -count 1000000

# 10 milionów losowych fraz
./generator random -f words.txt -count 10000000

# Losowe frazy z zakresem 2-5 słów
./generator random -f words_unique.txt -count 100000000000 -range 2 5 | ./brainwallet_gpu - adresy_unique.bin

# Losowe frazy z zakresem 4-10 słów
./generator random -f words.txt -count 1000000 -range 4 10
🔧 OPCJE DODATKOWE
Opcje liczb (-n i -randnum)
bash
# STAŁE liczby (obliczane z słowa)
./generator words -f words.txt -w 2 -n

# LOSOWE liczby (8-20 cyfr)
./generator words -f words.txt -w 2 -randnum

# Losowe liczby z własnym zakresem
./generator words -f words.txt -w 2 -randnum -l 6 12

# Stałe liczby + własny zakres
./generator words -f words.txt -w 2 -n -l 10 15
Opcje znaków specjalnych (-s i -randchar)
bash
# STAŁE znaki specjalne
./generator words -f words.txt -w 2 -s

# LOSOWE znaki specjalne
./generator words -f words.txt -w 2 -randchar

# Oba rodzaje znaków
./generator words -f words.txt -w 2 -s -randchar
Opcje tekstu
bash
# Leet speak (a→4, e→3, i→1, o→0, s→5)
./generator words -f words.txt -w 2 -leet

# Warianty wielkości liter
./generator words -f words.txt -w 2 -case

# Bez spacji
./generator words -f words.txt -w 2 -nospace

# Losowa kolejność słów
./generator words -f words.txt -w 2 -random
Opcje limitów
bash
# Limit kombinacji (np. 1 milion)
./generator words -f words.txt -w 2 -c 1000000

# Limit 10 milionów
./generator words -f words.txt -w 2 -c 10000000

# Limit dla losowych fraz
./generator random -f words.txt -count 1000000 -c 500000
Opcje wyjścia
bash
# Zapisz do pliku
./generator words -f words.txt -w 2 -o output.txt

# Liczba wątków (domyślnie 30)
./generator words -f words.txt -w 2 -t 20

# Zmiana separatora (domyślnie spacja)
./generator words -f words.txt -w 2 -sep _
./generator words -f words.txt -w 2 -sep -
🎯 KOMBINACJE WSZYSTKICH OPCJI
2 SŁOWA
bash
# Podstawowe
./generator words -f words.txt -w 2

# + liczby
./generator words -f words.txt -w 2 -n
./generator words -f words.txt -w 2 -randnum

# + znaki specjalne
./generator words -f words.txt -w 2 -s
./generator words -f words.txt -w 2 -randchar

# + leet speak
./generator words -f words.txt -w 2 -leet

# + case
./generator words -f words.txt -w 2 -case

# + bez spacji
./generator words -f words.txt -w 2 -nospace

# + wszystko razem (NAJWIĘCEJ KOMBINACJI)
./generator words -f words.txt -w 2 -n -s -leet -case
./generator words -f words.txt -w 2 -randnum -randchar -leet -case
./generator words -f words.txt -w 2 -randnum -randchar -leet -case -nospace

# + wszystko + limit
./generator words -f words.txt -w 2 -n -s -leet -case -c 1000000
3 SŁOWA
bash
# Podstawowe
./generator words -f words.txt -w 3

# + liczby
./generator words -f words.txt -w 3 -n
./generator words -f words.txt -w 3 -randnum

# + znaki specjalne
./generator words -f words.txt -w 3 -s
./generator words -f words.txt -w 3 -randchar

# + wszystko
./generator words -f words.txt -w 3 -n -s -leet -case
./generator words -f words.txt -w 3 -randnum -randchar -leet -case -nospace
4 SŁOWA
bash
# Podstawowe
./generator words -f words.txt -w 4

# + liczby + znaki + leet + case
./generator words -f words.txt -w 4 -n -s -leet -case

# + wszystko bez spacji
./generator words -f words.txt -w 4 -randnum -randchar -leet -case -nospace
🚀 KOMENDY Z POTOKIEM DO BRAINWALLET
bash
# 2 słowa podstawowe
./generator words -f words.txt -w 2 | ./brainwallet_gpu - adresy.bin

# 2 słowa + liczby
./generator words -f words.txt -w 2 -n | ./brainwallet_gpu - adresy.bin

# 2 słowa + losowe liczby
./generator words -f words.txt -w 2 -randnum | ./brainwallet_gpu - adresy.bin

# 2 słowa + znaki specjalne
./generator words -f words.txt -w 2 -s | ./brainwallet_gpu - adresy.bin

# 2 słowa + losowe znaki
./generator words -f words.txt -w 2 -randchar | ./brainwallet_gpu - adresy.bin

# 2 słowa + leet speak
./generator words -f words.txt -w 2 -leet | ./brainwallet_gpu - adresy.bin

# 2 słowa + case
./generator words -f words.txt -w 2 -case | ./brainwallet_gpu - adresy.bin

# 2 słowa + bez spacji
./generator words -f words.txt -w 2 -nospace | ./brainwallet_gpu - adresy.bin

# 2 słowa + WSZYSTKO (NAJWIĘCEJ KOMBINACJI)
./generator words -f words.txt -w 2 -n -s -leet -case | ./brainwallet_gpu - adresy.bin

# 2 słowa + WSZYSTKO + BEZ SPACJI
./generator words -f words.txt -w 2 -n -s -leet -case -nospace | ./brainwallet_gpu - adresy.bin

# 2 słowa + LOSOWE liczby + LOSOWE znaki + leet + case
./generator words -f words.txt -w 2 -randnum -randchar -leet -case | ./brainwallet_gpu - adresy.bin

# 3 słowa + wszystko
./generator words -f words.txt -w 3 -n -s -leet -case | ./brainwallet_gpu - adresy.bin

# 4 słowa + wszystko
./generator words -f words.txt -w 4 -n -s -leet -case | ./brainwallet_gpu - adresy.bin

# Liczby tylko
./generator numbers -l 10 12 | ./brainwallet_gpu - adresy.bin

# Losowe frazy
./generator random -f words.txt -count 1000000 -range 3 8 | ./brainwallet_gpu - adresy_unique.bin

# Losowe frazy + leet + case
./generator random -f words.txt -count 1000000 -range 3 8 -leet -case | ./brainwallet_gpu - adresy.bin

# Losowe frazy + wszystko
./generator random -f words.txt -count 1000000 -range 3 8 -randnum -randchar -leet -case | ./brainwallet_gpu - adresy.bin
📝 PODSUMOWANIE WSZYSTKICH OPCJI
Opcja	Opis	Przykład
-f <plik>	Plik ze słowami	-f words.txt
-o <plik>	Zapisz do pliku	-o output.txt
-w <2/3/4>	Liczba słów	-w 2
-n	Stałe liczby	-n
-randnum	Losowe liczby	-randnum
-s	Stałe znaki specjalne	-s
-randchar	Losowe znaki specjalne	-randchar
-nospace	Bez spacji	-nospace
-leet	Leet speak	-leet
-case	Warianty wielkości liter	-case
-random	Losowa kolejność słów	-random
-c <liczba>	Limit kombinacji	-c 1000000
-t <liczba>	Liczba wątków	-t 30
-l <min> <max>	Zakres długości liczby	-l 8 12
-sep <znak>	Separator	-sep _
-count <liczba>	Liczba losowych fraz	-count 1000000
-range <min> <max>	Zakres słów w losowej frazie	-range 3 8
-h	Pomoc	-h
a sklejone slowa jak?
Aby generować sklejone słowa (bez spacji), użyj opcji -nospace:

🔧 Sklejone słowa - podstawowe komendy:
bash
# 2 słowa sklejone
./generator words -f words.txt -w 2 -nospace | ./brainwallet_gpu - adresy.bin


# 3 słowa sklejone
./generator words -f words.txt -w 3 -nospace

# 4 słowa sklejone
./generator words -f words.txt -w 4 -nospace
🎯 Sklejone + inne opcje:
bash
# 2 słowa sklejone + liczby
./generator words -f words.txt -w 2 -nospace -n | ./brainwallet_gpu - adresy_unique.bin


# 2 słowa sklejone + losowe liczby
./generator words -f words.txt -w 2 -nospace -randnum

# 2 słowa sklejone + znaki specjalne
./generator words -f words.txt -w 2 -nospace -s

# 2 słowa sklejone + leet speak
./generator words -f words.txt -w 2 -nospace -leet

# 2 słowa sklejone + case
./generator words -f words.txt -w 2 -nospace -case

# 2 słowa sklejone + WSZYSTKO
./generator words -f words.txt -w 2 -nospace -n -s -leet -case

# 2 słowa sklejone + losowe liczby + losowe znaki + leet + case
./generator words -f words.txt -w 2 -nospace -randnum -randchar -leet -case
🚀 Sklejone słowa z potokiem do brainwallet:
bash
# 2 słowa sklejone
./generator words -f words.txt -w 2 -nospace | ./brainwallet_gpu - adresy.bin

# 2 słowa sklejone + liczby
./generator words -f words.txt -w 2 -nospace -n | ./brainwallet_gpu - adresy.bin

# 2 słowa sklejone + losowe liczby
./generator words -f words.txt -w 2 -nospace -randnum | ./brainwallet_gpu - adresy.bin

# 2 słowa sklejone + WSZYSTKO
./generator words -f words.txt -w 2 -nospace -n -s -leet -case | ./brainwallet_gpu - adresy.bin

# 3 słowa sklejone + wszystko
./generator words -f words.txt -w 3 -nospace -n -s -leet -case | ./brainwallet_gpu - adresy.bin

# 4 słowa sklejone + wszystko
./generator words -f words.txt -w 4 -nospace -n -s -leet -case | ./brainwallet_gpu - adresy.bin
📝 Przykład:
Dla słów: hello, world, bitcoin

Bez -nospace:

text
hello world
hello bitcoin
world hello
world bitcoin
bitcoin hello
bitcoin world
Z -nospace:

text
helloworld
hellobitcoin
worldhello
worldbitcoin
bitcoinhello
bitcoinworld
💡 Sklejone + losowe frazy:
bash
# Losowe frazy sklejone (3-8 słów)
./generator random -f words.txt -count 1000000 -range 3 8 -nospace

# Losowe frazy sklejone + wszystko
./generator random -f words.txt -count 1000000 -range 3 8 -nospace -randnum -randchar -leet -case

# Losowe frazy sklejone + limit
./generator random -f words.txt -count 1000000 -range 3 8 -nospace -c 500000






Rozumiem. Potrzebujesz README dla swojego brainwallet GPU crackera. Uwzględnię:

opis działania

wymagania (biblioteki, pliki)

komendy kompilacji

przykładowe uruchomienia

opcje (tryb compressed/uncompressed/both, batch)

obsługa dużych plików (mmap, batch processing)

format pliku wejściowego i wyjściowego

informacje o wydajności i optymalizacji.

Oto proponowany plik README.md:

🧠 Brainwallet GPU Cracker
Program do masowego sprawdzania, czy frazy (hasła, zdania) generują adresy Bitcoin obecne w podanej bazie (pliku adresy.bin). Wykorzystuje GPU (CUDA) i gotowe tabele punktów gtableX.bin / gtableY.bin do szybkiego mnożenia punktów krzywej secp256k1. Działa w trybie batch (partie fraz), nie zużywa całej pamięci RAM przy ogromnych słownikach (np. 1 TB) dzięki strumieniowemu odczytowi i przetwarzaniu partiami.

✨ Funkcje
Szybkie obliczenia EC – używa GTable (prekompilowane punkty) zamiast pełnego mnożenia.

Indeks 24-bitowy – przyspiesza wyszukiwanie w bazie (binary search z ograniczeniem do kilku rekordów).

Batch processing – przetwarza słownik partiami (domyślnie 1 mln fraz), minimalizując zużycie RAM.

mmap – baza adresów jest mapowana bez kopiowania do RAM, obsługa plików >11 GB.

Zapis frazy źródłowej – w pliku wynikowym zapisywana jest oryginalna fraza, która wygenerowała klucz.

Tryby adresów – można skanować tylko compressed, tylko uncompressed lub oba (domyślnie).

Obsługa standardowego wejścia – można przekazywać słownik potokiem (np. cat słownik.txt | ./brainwallet_gpu - adresy.bin).

📦 Wymagania
System: Linux (x86_64) z obsługą CUDA (np. Ubuntu 20.04+)

Karta graficzna: NVIDIA z Compute Capability 3.0+ (zalecane >= 6.0)

Biblioteki: CUDA Toolkit (>= 10.0), OpenSSL (libssl-dev, libcrypto), libsecp256k1, pthread

Pliki danych (konieczne):

adresy.bin – posortowana binarna baza 20‑bajtowych hashów (RIPEMD‑160) adresów Bitcoin (wielokrotność 20 bajtów)

gtableX.bin i gtableY.bin – wygenerowane za pomocą generate_gtable (lub dostarczone)

🔧 Kompilacja
Upewnij się, że masz zainstalowane zależności:

bash
sudo apt install nvidia-cuda-toolkit libssl-dev libsecp256k1-dev
Skompiluj program:

bash
nvcc -std=c++11 -O2 -D_FORTIFY_SOURCE=0 -Xcompiler="-D_FORTIFY_SOURCE=0" -o brainwallet_gpu brainwallet_gpu.cu -lssl -lcrypto -lsecp256k1 -lpthread
Jeśli masz problem z __builtin_dynamic_object_size, dodaj flagi jak wyżej (wyłączają _FORTIFY_SOURCE). Kompilacja może generować ostrzeżenia o przestarzałych funkcjach OpenSSL – są one bezpieczne do ignorowania.

🚀 Uruchomienie
Podstawowa składnia:

bash
./brainwallet_gpu <ścieżka_do_słownika> <ścieżka_do_adresy.bin> [--mode=comp|uncomp|both]
ścieżka_do_słownika – plik tekstowy z jedną frazą na linię, lub - dla odczytu ze standardowego wejścia.

ścieżka_do_adresy.bin – plik bazy adresów.

--mode (opcjonalny) – tryb skanowania: comp (tylko compressed), uncomp (tylko uncompressed), both (oba, domyślnie).

Przykłady:

bash
# Skanuj słownik.txt, oba typy adresów
./brainwallet_gpu słownik.txt adresy.bin

# Tylko adresy skompresowane
./brainwallet_gpu słownik.txt adresy.bin --mode=comp

# Przekazanie słownika przez potok (np. z generatora fraz)
cat wygenerowane_frazy.txt | ./brainwallet_gpu - adresy.bin

# Z użyciem programu generującego frazy (np. napisanego w C++)
./generator_fraz | ./brainwallet_gpu - adresy.bin
📁 Pliki wejściowe/wyjściowe
Wejściowy słownik
UTF-8, jedna fraza na linię.

Program automatycznie usuwa puste linie.

Długość pojedynczej frazy nie może przekraczać 127 znaków (stała MAX_PASS_LEN – można zmienić w kodzie).

Przy bardzo dużych plikach (np. 1 TB) program czyta strumieniowo i przetwarza partiami – nie ładuje całego pliku do RAM.

Baza adresów (adresy.bin)
Binarny plik zawierający posortowane rosnąco 20‑bajtowe hashe RIPEMD‑160 (bez prefiksu 0x00).

Rozmiar musi być wielokrotnością 20.

Plik jest mapowany przez mmap – nie jest kopiowany do pamięci procesu.

Wynik (found_brainwallet.txt)
Dołączane są nowe znalezione pary.

Format każdego wpisu:

text
FRAZA: <fraza>
KEY: <klucz_prywatny_hex>
TYP: COMPRESSED|UNCOMPRESSED
ADDR: <adres_Bitcoin>
---
⚙️ Strojenie wydajności
Bloki/wątki: W pliku źródłowym zdefiniowane są stałe BLOCKS i THREADS. Dla nowszych kart (RTX 30xx/40xx) można zwiększyć BLOCKS np. do 16384, a THREADS zmniejszyć do 128–256. Dla starszych kart (GTX 10xx) użyj BLOCKS=512, THREADS=256.

Wielkość partii: BATCH_SIZE (domyślnie 1 000 000) – im większa partia, tym mniej wywołań kernela, ale większe zużycie pamięci GPU na dane. Dla słowników >10 mld fraz ustaw mniejszy batch (np. 100 000), aby uniknąć timeoutu.

Filtrowanie prefiksowe: Jeśli baza jest mała (np. < 10 mln adresów), włączone automatycznie – pomija obliczenia EC dla fraz, których prefiks 24‑bitowy nie występuje w bazie. Dla dużych baz (prawie wszystkie prefiksy) nie daje dużego zysku.

Tryb adresów: Wybór tylko jednego typu (--mode=comp lub --mode=uncomp) zmniejsza pracę o połowę.

🔗 Integracja z zewnętrznym generatorem fraz
Program czyta słownik ze standardowego wejścia (-), więc możesz podłączyć dowolny program generujący frazy (np. w C++), który wypisuje je na stdout, a Twój cracker przetwarza je na bieżąco.

Przykład w C++ (prosty generator):

cpp
// generator_fraz.cpp
#include <iostream>
int main() {
    for (int i = 0; i < 1000000; ++i) {
        std::cout << "haslo" << i << "\n";
    }
    return 0;
}
Kompilacja i użycie:

bash
g++ -O2 generator_fraz.cpp -o generator_fraz
./generator_fraz | ./brainwallet_gpu - adresy.bin
🛠️ Rozwiązywanie problemów
Błąd __builtin_dynamic_object_size – użyj flag kompilacji podanych wyżej (wyłączają _FORTIFY_SOURCE).

Brak plików gtableX.bin / gtableY.bin – wygeneruj je za pomocą dostarczonego generate_gtable (lub pobierz z zaufanego źródła).

Niska wydajność (np. 5 MH/s) – sprawdź, czy używasz odpowiednich stałych BLOCKS/THREADS dla swojej karty, oraz czy tryb --mode ogranicza pracę. Możesz też spróbować zwiększyć BATCH_SIZE i użyć cudaOccupancyMaxPotentialBlockSize.

Program zatrzymuje się / zawiesza – może być zbyt duża partia (BATCH_SIZE) – zmniejsz do 100 000 – 500 000.

Brak pamięci VRAM – jeśli baza jest bardzo duża (>24 GB) lub masz mało VRAM, program może nie zaalokować indeksu 24‑bitowego (128 MB) – wtedy używa wolniejszego binary search bez indeksu.