# CosplayNusa Mobile + Laravel API

Project ini berisi aplikasi mobile **Flutter** dan backend **Laravel 13 + Sanctum + MySQL** untuk rental kostum cosplay. Struktur, alur role, palet, dan behavior light/dark mengikuti proyek sumber:

`C:\Users\DELL\Herd\rental-cosplay`

## Struktur

```text
nusa_cosrent/
├── lib/                    # Flutter mobile app
│   ├── config/             # URL API
│   ├── data/               # HTTP client, token, model, repository
│   ├── features/           # auth, customer, owner, admin, profile
│   ├── state/              # session dan theme
│   ├── theme/              # light/dark theme
│   └── widgets/            # komponen UI
└── laravel/                # backend API + web reference
    ├── app/Http/Controllers/Api/V1
    ├── database/migrations
    ├── database/seeders
    └── routes/api.php
```

MySQL adalah source of truth. Implementasi lama SQLite telah dihapus dari runtime mobile; `main.dart` hanya menginisialisasi API Laravel dan secure token store.

## Fitur

- Auth Sanctum: login dengan email atau username, register customer/owner, session persisten, logout, dan pemulihan session dengan `/auth/me`.
- Customer: katalog, search/filter, detail kostum, booking, riwayat order, return, dan laporan lost.
- Cosrent Owner: CRUD kostum, approve/reject/complete order, daftar order, dan resolve issue.
- Admin: dashboard, CRUD user/role, seluruh order, kostum, dan issue.
- Bukti issue dapat dipilih dari perangkat melalui file picker dan dikirim sebagai multipart.
- Light/dark mode mengikuti sistem atau pilihan `System`, `Light`, `Dark`; preferensi disimpan dengan key `cosrent-theme`.
- UI mobile mempertahankan palet source: violet `#7C3AED`, rose `#E11D48`, ink `#0F172A`, light `#F8F7F4`, dark `#020617`.
- Responsive: bottom navigation di phone dan `NavigationRail` di tablet/desktop.

## Menjalankan backend

Prasyarat: PHP 8.4, Composer, Node.js (untuk asset web Laravel), dan MySQL 8.

```powershell
cd C:\Users\DELL\Herd\nusa_cosrent\laravel

composer install
Copy-Item .env.example .env       # jika .env belum tersedia
php artisan key:generate

# Buat database sekali saja
& 'C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe' `
  -h 127.0.0.1 -P 3306 -u root `
  -e "CREATE DATABASE IF NOT EXISTS rental_cosplay CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Atur kredensial MySQL pada .env bila diperlukan
php artisan migrate --seed
# migration ini menambahkan username untuk login email/username
npm install
npm run build
```

Backend disajikan oleh **Herd** pada domain lokal
`https://nusa_rental_cosplay.test` (diarahkan ke `127.0.0.1` lewat hosts file),
sehingga tidak perlu `php artisan serve`. Untuk Android tetap dapat memakai
`php artisan serve --host=0.0.0.0 --port=8000` sebagai host alternatif.

API health check:

```text
GET https://nusa_rental_cosplay.test/api/v1/health
```

## Menjalankan Flutter

```powershell
cd C:\Users\DELL\Herd\nusa_cosrent
flutter pub get

# Default: memakai domain Herd (web, desktop, iOS simulator)
flutter run

# Android: domain .test tidak bisa di-resolve emulator/device, gunakan host PC
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Device fisik: gunakan IP komputer yang dapat dijangkau device
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Tanpa `API_BASE_URL`, aplikasi memakai `https://nusa_rental_cosplay.test` lalu
mengecek `/api/v1/health`; bila gagal, di Android otomatis mencoba host Android
Studio (`10.0.2.2`) lalu Genymotion (`10.0.3.2`).

Bearer token disimpan melalui `flutter_secure_storage`; password tidak pernah disimpan oleh mobile.

## Jika login tidak berhasil

1. Pastikan backend aktif dan cek `https://nusa_rental_cosplay.test/api/v1/health`.
2. Android emulator tidak bisa me-resolve domain `.test`; pakai `http://10.0.2.2:8000/api/v1`.
3. Android device fisik harus memakai IP komputer pada Wi-Fi yang sama, bukan `127.0.0.1`.
4. Untuk URL HTTP lokal, gunakan `flutter run`/`app-debug.apk`; build production sebaiknya memakai HTTPS.
5. Login menerima email maupun username. Username seed lokal: `customer`, `owner`, atau `admin`.

## Akun seed lokal

| Role | Username | Email | Password |
| --- | --- | --- | --- |
| Customer | `customer` | `customer@cosplaynusa.test` | `password` |
| Cosrent Owner | `owner` | `owner@cosplaynusa.test` | `password` |
| Admin | `admin` | `admin@cosplaynusa.test` | `password` |

Seeder membuat user, katalog contoh, dan satu order pending. Jalankan `php artisan db:seed --force` untuk mengisi ulang data demo secara idempotent.

## CRUD API utama

Semua endpoint memakai prefix `/api/v1` dan, kecuali register/login/health, memakai Sanctum bearer token.

- Auth: `POST /auth/register`, `POST /auth/login` (field `login` dapat berisi email atau username), `GET /auth/me`, `POST /auth/logout`.
- Catalog: `GET /costumes`, `GET /costumes/categories`, `GET /costumes/{id}`.
- Customer: `GET /customer/orders`, `POST /customer/costumes/{id}/orders`, `GET /customer/orders/{id}`, `POST /customer/orders/{id}/return`, `POST /customer/orders/{id}/loss-report`, `DELETE /customer/orders/{id}`.
- Owner: `GET/POST /owner/costumes`, `GET/PATCH/DELETE /owner/costumes/{id}`, `GET /owner/orders`, approve/reject/complete, `GET /owner/issues`.
- Admin: `GET/POST/PATCH/DELETE /admin/users`, `GET /admin/orders`, `GET/PATCH/DELETE /admin/costumes`, `GET/PATCH/DELETE /admin/issues`.

Pricing, role, status transition, dan stok dihitung/di-jaga server-side melalui Laravel action/policy. Mobile tidak menjadi sumber data bisnis.

## Validasi

```powershell
# Flutter
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
flutter build windows --debug

# Laravel
cd laravel
php artisan test
```

## Catatan production

- Gunakan HTTPS dan set `CORS_ALLOWED_ORIGINS` ke origin web yang benar.
- Set `APP_DEBUG=false`, gunakan kredensial MySQL khusus, dan jangan commit `.env`.
- Ganti signing Android dan sesuaikan metadata rilis sebelum toko.
- Bukti issue disimpan di `storage/app/private`; gunakan object storage yang sesuai untuk deployment multi-instance.
- Token Sanctum dikonfigurasi kedaluwarsa 7 hari melalui `SANCTUM_EXPIRATION`.
