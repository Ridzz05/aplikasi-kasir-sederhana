# Panduan Build Release - Aplikasi Kasir Sederhana

## Informasi Release

- **Versi**: 1.0.0
- **Build**: 1
- **Status**: Production Ready
- **Tanggal**: 2026-01-17

## Perubahan untuk Release Mode

✅ **Semua print statements dan debugPrint telah dihapus**
✅ **Analyzer dikonfigurasi untuk mendeteksi print statements** (avoid_print: true)
✅ **Aplikasi siap untuk production deployment**

## Cara Build untuk Android

### APK Release

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### AAB (Android App Bundle) - Untuk Play Store

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Cara Build untuk iOS

```bash
flutter build ios --release
```

Output akan tersedia di `build/ios/iphoneos/`

## Cara Build untuk Web

```bash
flutter build web --release
```

Output: `build/web/`

## Cara Build untuk Windows

```bash
flutter build windows --release
```

Output: `build/windows/runner/Release/`

## Cara Build untuk Linux

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

## Cara Build untuk macOS

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/`

## Verifikasi Release Build

Untuk memastikan tidak ada print statements tersisa dalam release build:

```bash
# Analyze kode untuk memastikan tidak ada print statements
flutter analyze

# Atau dengan verbose
flutter analyze --verbose
```

## Checklist Pre-Release

- ✅ Semua print statements dihapus
- ✅ debugPrint dihapus dari production code
- ✅ avoid_print lint rule diaktifkan
- ✅ Version code dan version name sudah tepat
- ✅ App ID sudah sesuai (com.kasir.sederhana)
- ✅ Icons dan splash screen sudah di-configure
- ✅ Permissions sudah di-configure dengan benar
- ✅ Database migration tested
- ✅ Semua feature sudah di-test

## Konfigurasi Release

### Android Signing (untuk Play Store)

Buat keystore jika belum ada:
```bash
keytool -genkey -v -keystore ~/kasir_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kasir_key
```

Edit `android/local.properties`:
```properties
storeFile=/path/to/kasir_key.jks
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=kasir_key
```

## Performance Tips untuk Release

- Build size optimization otomatis dilakukan saat release
- ProGuard/R8 obfuscation otomatis diaktifkan untuk Android
- Flutter akan membuat native code yang dioptimalkan

## Testing Release Build

```bash
# Test di device fisik atau emulator
flutter install -v

# Atau langsung run release build
flutter run --release
```

## Notes

- Release mode akan disable semua debug logs
- Performance akan lebih baik dibanding debug mode
- APK/AAB ukurannya lebih kecil karena optimisasi
- Tidak ada debug symbols dalam release build

## Support

Untuk informasi lebih lanjut tentang Flutter release builds:
https://flutter.dev/docs/deployment/android
https://flutter.dev/docs/deployment/ios
