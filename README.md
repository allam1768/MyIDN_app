<div align="center">

  <img src="assets/icon/app_icon.png" width="100" height="100" alt="MyIDN Logo" style="border-radius: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" />

  # 🎓 MyIDN (IDN Reminder App)
  
  **Aplikasi Manajemen Kuliah, Presensi Otomatis, & Laporan Harian Terintegrasi LMS Politeknik IDN**

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![State Management](https://img.shields.io/badge/State-Riverpod_2.x-1389FD?style=for-the-badge&logo=riverpod&logoColor=white)](https://riverpod.dev)
  [![Security](https://img.shields.io/badge/License-Ed25519_Hardware_Locked-22C55E?style=for-the-badge&logo=shield&logoColor=white)](#-sistem-lisensi-hardware-locked-ed25519)
  [![Latest Release](https://img.shields.io/github/v/release/allam1768/MyIDN_app?style=for-the-badge&color=blue&logo=github)](https://github.com/allam1768/MyIDN_app/releases)

  <br />

  <p align="center">
    <a href="https://github.com/allam1768/MyIDN_app/releases/latest">
      <img src="https://img.shields.io/badge/📥_Download_APK_Terbaru-Click_Here-1F81FF?style=for-the-badge&logo=android&logoColor=white" height="40" alt="Download APK" />
    </a>
  </p>

</div>

---

## 📖 Daftar Isi

1. [Tentang MyIDN](#-tentang-myidn)
2. [Fitur Unggulan](#-fitur-unggulan)
3. [Cara Download & Install lewat GitHub](#-cara-download--install-lewat-github)
4. [Sistem Lisensi Hardware-Locked Ed25519](#-sistem-lisensi-hardware-locked-ed25519)
5. [Tech Stack & Arsitektur](#-tech-stack--arsitektur)
6. [Panduan Developer (Build dari Source)](#-panduan-developer-build-dari-source)
7. [Kualitas Kode & Pengujian](#-kualitas-kode--pengujian)
8. [Author & Lisensi](#-author--lisensi)

---

## 🌟 Tentang MyIDN

**MyIDN** adalah aplikasi asisten pintar yang dirancang khusus untuk mahasiswa Politeknik IDN Bogor. Aplikasi ini mengotomatiskan seluruh alur perkuliahan: mulai dari pengingat jadwal kelas harian, pengisian presensi absensi, monitoring tugas & deadline, pengajuan surat izin sakit resmi berformat PDF, hingga pelaporan ibadah dan poin kebaikan santri secara terpusat.

Dilengkapi dengan desain UI clean, modern, dan responsif serta dipersenjatai perlindungan lisensi anti-pembajakan seumur hidup (*Offline Hardware-Locked Cryptography*).

---

## ✨ Fitur Unggulan

| Fitur | Deskripsi |
| :--- | :--- |
| ⚡ **Smart Daily Briefing** | Ringkasan kartu agenda interaktif di dashboard: menampilkan kelas yang sedang berlangsung, sisa waktu kelas berikutnya, tugas yang mendekati deadline, serta status laporan harian. |
| 📋 **Presensi Absensi Kuliah** | Auto-fetch jadwal absensi bulanan dari server LMS. Terproteksi otorisasi khusus: input presensi bersih tanpa kebocoran kode untuk mahasiswa umum, dan auto-fill kode unik bagi akun creator. |
| 📅 **Jadwal & Ruang Kuliah** | Jadwal kelas harian lengkap dengan status *Sekarang*, *Akan Datang*, atau *Selesai*, nama dosen pengampu, dan integrasi ikon mata kuliah otomatis. |
| 📝 **Manajemen Tugas & Deadline** | Monitoring daftar tugas yang belum dikerjakan (pending) maupun yang sudah selesai. Dilengkapi form pengumpulan tugas langsung ke server LMS. |
| 📄 **Surat Izin Resmi (PDF Generator)** | Generator dokumen PDF resmi ber-kop Politeknik IDN untuk izin sakit atau keperluan keluarga, lengkap dengan canvas tanda tangan pensil digital dan auto-forward pesan formal ke WhatsApp kemahasiswaan. |
| 🕌 **Laporan Ibadah Harian** | Checklist interaktif sholat 5 waktu berjamaah di masjid, tilawah Al-Qur'an, sholat sunnah rawatib/dhuha/tahajjud, dzikir pagi-petang, dan puasa sunnah. |
| 🌟 **Poin Kebaikan Santri** | Integrasi cepat ke sistem pencatatan poin kebaikan mahasiswa IDN harian. |
| 🔔 **Notifikasi Pengingat Otomatis** | Pengingat alarm tepat waktu sebelum jam kuliah dimulai dan alarm malam (22:00 WIB) untuk pengisian laporan ibadah & kebaikan. |
| 🔐 **Anti-Piracy License Gatekeeper** | Sistem lisensi Ed25519 hardware-locked seumur hidup: 1 kode lisensi hanya dapat diaktifkan pada 1 perangkat HP pembeli saja. |
| 🛠️ **In-App Key Studio (Admin Only)** | Menu khusus akun Allam Permata Putra untuk men-generate serial key bagi pembeli baru langsung dari aplikasi. |

---

## 📱 Cara Download & Install lewat GitHub

Pengguna dapat mengunduh dan memasang aplikasi MyIDN langsung dari repositori GitHub ini:

### Langkah 1: Unduh Berkas APK
1. Buka halaman **[Releases](https://github.com/allam1768/MyIDN_app/releases)**.
2. Pada bagian release terbaru (*Latest*), unduh berkas **`MyIDN-release.apk`**.

### Langkah 2: Pasang (Install) di Android
1. Buka berkas `MyIDN-release.apk` yang telah diunduh pada smartphone Android Anda.
2. Tekan **Install**.
3. **Catatan Google Play Protect**:
   * Karena aplikasi ini didistribusikan langsung (*direct sideload*), Google Play Protect mungkin menampilkan peringatan *"Blocked by Play Protect"* atau *"Aplikasi dari sumber tidak dikenal"*.
   * Tekan **Rincian lainnya (More details)**.
   * Pilih **Tetap instal (Install anyway)**.

### Langkah 3: Aktivasi & Masuk
1. Buka aplikasi **MyIDN**.
2. Pada layar **Aktivasi Lisensi**, salin **Kode Perangkat** (contoh: `IDN-7F8A-9B21`).
3. Kirimkan Kode Perangkat tersebut ke Developer/Admin ([Allam Permata Putra](#-author--lisensi)) untuk mendapatkan **Serial Key Resmi**.
4. Tempelkan Serial Key dan tekan **Aktivasi Sekarang**. Aplikasi akan aktif permanen seumur hidup!

---

## 🔐 Sistem Lisensi Hardware-Locked Ed25519

Aplikasi ini menggunakan algoritma kriptografi asimetris **Ed25519**:

```
[Target Device ID]  --->  [Private Key (Developer Only)]  --->  [IDN-KEY-XXXX Serial]
                                                                        │
                                                                        ▼
[Target Device ID]  +   [Public Key (Hardcoded in App)]   --->  [Valid / Activated! ✅]
[Different Device]  +   [Public Key (Hardcoded in App)]   --->  [Invalid / Blocked! ❌]
```

* **Anti-Piracy**: Jika seorang pembeli menyalin APK atau memberikan serial key-nya kepada temannya, aplikasi **tidak akan bisa diaktifkan** di HP temannya karena Device ID hardware berbeda.
* **100% Offline**: Verifikasi keaslian kunci dilakukan secara matematika murni tanpa memerlukan server lisensi pihak ketiga.

### Membuat Serial Key untuk Pembeli (Bagi Admin / Creator)
* **Dari HP**: Login akun creator > Buka menu **Key Studio** di dashboard > Tempel Device ID > Tekan **Generate**.
* **Dari Terminal Laptop**:
  ```bash
  dart run tool/keygen.dart --device "KODE_DEVICE_PEMBELI"
  ```

---

## 🛠️ Tech Stack & Arsitektur

MyIDN dibangun dengan standar **Clean Architecture**, **SOLID**, dan **Separation of Concerns**:

* **Framework**: Flutter 3.x / Dart 3.x
* **State Management**: `flutter_riverpod: ^2.6.1` (Deklaratif, auto-dispose, & auto-refresh)
* **Networking & Session**: `dio: ^5.7.0` + `cookie_jar: ^4.0.8` + `dio_cookie_manager: ^3.1.1`
* **Cryptography**: `cryptography: ^2.9.0` (Ed25519 Digital Signatures)
* **PDF Engine**: `pdf: ^3.12.0` & `printing: ^5.14.3`
* **Local Notifications**: `flutter_local_notifications: ^22.3.0` & `timezone: ^0.11.1`
* **UI Design System**: `flutter_screenutil: ^5.9.3` & `google_fonts: ^8.2.1` (DM Sans typography)
* **Security**: SSL Hardening khusus domain LMS resmi Politeknik IDN.

---

## 💻 Panduan Developer (Build dari Source)

Bagi pengembang yang ingin berkontribusi atau mengompilasi sendiri:

### 1. Prasyarat
* Flutter SDK versi 3.19 ke atas (`flutter --version`)
* Android SDK dengan Java 17

### 2. Kloning Repositori
```bash
git clone https://github.com/allam1768/MyIDN_app.git
cd MyIDN_app
```

### 3. Install Dependensi
```bash
flutter pub get
```

### 4. Jalankan Pengujian
```bash
flutter test
```

### 5. Jalankan Aplikasi
```bash
flutter run
```

### 6. Build Release APK
```bash
flutter build apk --release
```
Berkas APK hasil build akan berlokasi di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Kualitas Kode & Pengujian

* **Static Analysis**: `dart analyze --fatal-infos` lolos dengan **0 Issues** (Clean Code).
* **Code Formatting**: 100% mengikuti pedoman resmi *Effective Dart* (`dart format`).
* **Automated Unit & Widget Tests**: Seluruh 35 skenario pengujian di folder `test/` lolos (`All tests passed!`).

---

## 👨‍💻 Author & Lisensi

Dibuat dan dikembangkan oleh:
* **Allam Permata Putra**
* GitHub: [@allam1768](https://github.com/allam1768)
* Email: [putraapermataa@gmail.com](mailto:putraapermataa@gmail.com)

*Hak Cipta © 2026 Allam Permata Putra. Seluruh hak cipta dilindungi undang-undang.*
