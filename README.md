# RL Clicker

**Instagram Video & Reels İndirici** — Android ve Linux için

---

## Nedir?

RL Clicker, elinizdeki Instagram Reel / video bağlantılarını alıp videoları cihazınıza indiren hafif, gizlilik odaklı bir uygulamadır.

### Ne Yapar ✅

- Genel (public) Instagram Reel ve video bağlantılarını çözümler
- Videoları cihaza indirir (`~/Downloads/RL_Clicker/` veya Android Movies klasörü)
- Birden fazla bağlantıyı aynı anda kuyruğa alıp eş zamanlı indirir
- İndirme geçmişini gösterir; tamamlanan videoyu oynatır veya klasörde açar

### Ne Yapmaz ❌

- Instagram'a giriş yapılmaz, şifre veya oturum bilgisi toplanmaz
- Özel (private) hesaplara erişilmez
- Cookie / token / session takip edilmez
- DRM veya erişim kısıtlamaları bypass edilmez

---

## Platform Desteği

| Platform                       | Durum            |
| ------------------------------ | ---------------- |
| 🐧 Linux (x64)                 | ✅ Destekleniyor |
| 🤖 Android (arm64, arm32, x64) | ✅ Destekleniyor |

---

## Kurulum

### Linux

```bash
# Release binary'yi çalıştır
./build/linux/x64/release/bundle/rl_clicker
```

veya AppImage olarak paketlemek için:

```bash
bash scripts/build_appimage.sh
```

### Android

Debug APK:

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

Release APK:

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

---

## Geliştirme

### Gereksinimler

- Flutter SDK ≥ 3.10.0 / Dart ≥ 3.0.0
- Android Studio veya VS Code (Flutter eklentisiyle)
- Linux için: `cmake`, `ninja-build`, `libgtk-3-dev`, `pkg-config`

### Testler

```bash
flutter test          # 26 test, hepsi geçmeli
flutter analyze       # Analiz hatası olmamalı
```

### Proje Yapısı

```
lib/
├── app.dart                    # Uygulama kökü, tema, NavigationBar
├── main.dart                   # Giriş noktası, servis bağlantıları
├── models/                     # Veri modelleri
│   ├── download_task.dart
│   ├── download_progress.dart
│   └── resolved_video.dart
├── services/                   # İş mantığı servisleri
│   ├── video_resolver.dart     # Instagram embed/OG/HTML çözümleyici
│   ├── downloader_service.dart # Akışlı chunk indirme, .part dosyası
│   ├── download_queue_service.dart  # Kuyruk yönetimi, eş zamanlılık
│   ├── storage_service.dart    # Dosya yolu, çakışma önleme
│   ├── settings_service.dart   # SharedPreferences ayarları
│   ├── clipboard_service.dart  # Pano URL tespiti
│   ├── notification_service.dart    # Yerel bildirimler
│   └── instagram_service.dart  # Resolver + parser façade
├── utils/
│   ├── url_validator.dart      # Regex tabanlı Instagram URL doğrulama
│   ├── url_parser.dart         # Çoklu URL ayrıştırma ve normalize
│   ├── filename_utils.dart     # RL_Clicker_YYYYMMDD_HHMMSS.mp4
│   └── error_utils.dart        # Hata eşleme
├── widgets/                    # Yeniden kullanılabilir UI bileşenleri
└── screens/                    # Home, Downloads, Settings ekranları
```

---

## Lisans

MIT License — Kişisel kullanım için serbesttir.
