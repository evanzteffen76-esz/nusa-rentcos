# CosplayNusa Laravel API

Backend ini adalah adaptasi dari `C:\Users\DELL\Herd\rental-cosplay` untuk menjadi source of truth Flutter. Web Blade tetap tersedia sebagai referensi, tetapi mobile memakai REST API Sanctum di prefix `/api/v1`.

## Setup lokal

```powershell
composer install
Copy-Item .env.example .env
php artisan key:generate
php artisan migrate --seed
npm install
npm run build
php artisan serve --host=0.0.0.0 --port=8000
```

Pastikan MySQL berjalan dan `rental_cosplay` tersedia. Nilai default `.env` lokal:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rental_cosplay
DB_USERNAME=root
DB_PASSWORD=
```

## Role dan data demo

Seeder menyediakan `customer@cosplaynusa.test`, `owner@cosplaynusa.test`, dan `admin@cosplaynusa.test` dengan password `password`. Jangan menjalankan seeder demo pada database production.

## API ringkas

- `POST /api/v1/auth/register` dan `POST /api/v1/auth/login` — issue Sanctum token; login menerima `login` berupa email atau username.
- `GET /api/v1/costumes` dan `GET /api/v1/costumes/categories` — katalog published.
- `GET/POST /api/v1/owner/costumes` dan `GET/PATCH/DELETE /api/v1/owner/costumes/{id}` — CRUD kostum owner.
- `GET /api/v1/customer/orders`, `POST /api/v1/customer/costumes/{id}/orders`, `POST /api/v1/customer/orders/{id}/return`, `DELETE /api/v1/customer/orders/{id}` — booking customer.
- `GET /api/v1/owner/orders`, `PATCH .../approve`, `.../reject`, `.../complete`, `GET /api/v1/owner/issues` — operasional owner.
- `GET/POST/PATCH/DELETE /api/v1/admin/users`, `GET /api/v1/admin/orders`, `GET/PATCH/DELETE /api/v1/admin/costumes`, `GET/PATCH/DELETE /api/v1/admin/issues` — CRUD admin.

Semua response resource memakai envelope Laravel `{ "data": ... }`; error validasi memakai HTTP 422 dengan field `errors`.

## Test

```powershell
php artisan test
```
# nusa-cosweb
# nusa-cosweb
# nusa-cosweb
