# Aplikasi Kasir Sederhana

Aplikasi kasir ini bersifat open source, semua orang bebas melakukan edit, publish dan bahkan merilisnya sebagai aplikasi komersial. Aplikasi ini dibuat menggunakan Flutter dan SQLite untuk manajemen database lokal.

## Fitur

- **Manajemen Produk**: Tambah, edit, dan hapus produk dengan gambar, harga, dan stok
- **Sistem Kategori**: Kelompokkan produk berdasarkan kategori dengan warna yang dapat disesuaikan
- **Proses Transaksi**: Buat transaksi penjualan dengan daftar produk yang dibeli
- **Laporan Penjualan**: Lihat histori transaksi dan laporan harian/bulanan
- **Manajemen Stok**: Update stok produk secara otomatis setelah transaksi
- **Tampilan Responsif**: Dapat digunakan di berbagai ukuran layar
- **Mode Web**: Dapat dijalankan di browser dengan dukungan simulasi database

## Persyaratan Sistem

- Flutter 2.0 atau lebih tinggi
- Dart 2.12 atau lebih tinggi
- Perangkat Android, iOS, atau browser web

## Instalasi

1. Pastikan Flutter sudah terinstal di komputer Anda
2. Clone repositori ini:
```bash
git clone https://github.com/username/aplikasi-kasir-sederhana.git
```
3. Masuk ke direktori proyek:
```bash
cd aplikasi-kasir-sederhana
```
4. Install dependensi:
```bash
flutter pub get
```
5. Jalankan aplikasi:
```bash
flutter run
```

## Demo Aplikasi

- **Android APK**: [https://github.com/username/aplikasi-kasir-sederhana/releases](https://github.com/Ridzz05/aplikasi-kasir-sederhana/releases)

## Struktur Proyek

- `lib/models/` - Model data (Product, Category, Transaction)
- `lib/screens/` - Halaman UI aplikasi
- `lib/database/` - Konfigurasi database dan helper
- `lib/providers/` - State management menggunakan Provider
- `lib/widgets/` - Widget yang dapat digunakan kembali
- `lib/utils/` - Utilitas dan helper functions

## Kontribusi

Kontribusi selalu disambut baik! Jika Anda ingin berkontribusi:

1. Fork repositori
2. Buat branch untuk fitur Anda (`git checkout -b feature/amazing-feature`)
3. Commit perubahan Anda (`git commit -m 'Add some amazing feature'`)
4. Push ke branch (`git push origin feature/amazing-feature`)
5. Buka Pull Request

## Lisensi

Proyek ini dilisensikan di bawah lisensi MIT - lihat file LICENSE untuk detailnya.