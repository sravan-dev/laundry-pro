# LaundryPro 🧺

A full-stack laundry management app with a **Customer App**, **Delivery Boy App**, and **Admin Panel**.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Customer App | Flutter (Android/iOS/macOS) |
| Delivery App | Flutter (Android/iOS/macOS) |
| Admin Panel | PHP + Tailwind CSS |
| Backend API | PHP + SQLite |

## Project Structure

```
├── backend/
│   ├── admin/          # Admin panel (PHP + Tailwind CSS)
│   ├── api/            # REST API endpoints (PHP)
│   │   ├── auth/       # Login & Register
│   │   ├── customer/   # Orders, Services, Profile
│   │   ├── delivery/   # Rider order management
│   │   └── admin/      # Admin CRUD endpoints
│   └── database/       # SQLite DB (auto-created)
├── customer_app/       # Flutter Customer App
└── delivery_app/       # Flutter Delivery Boy App
```

## Features

### Customer App (Laundry Pro)
- Register / Login
- Browse services (Wash & Iron, Ironing, Dry Cleaning, Darning)
- Place orders — 4-step wizard (Items → Options → Delivery → Payment)
- Track orders with live status progress bar
- View order history
- Edit profile

### Delivery Boy App (Laundry Boy)
- Login
- Dashboard with Active / Delivered / All tabs
- Auto-refresh every 30 seconds + pull-to-refresh + manual refresh
- Order detail with one-tap status updates
- Full order info (customer, addresses, items, preferences)

### Admin Panel
- Dashboard with stats (customers, delivery boys, orders, revenue)
- **Customers** — Add / Edit / Delete / Search
- **Delivery Boys** — Add / Edit / Delete / Search
- **Orders** — View detail, assign delivery boy, change status, delete, filter
- **Services** — Add / Edit / Delete

## Setup

### Backend

```bash
# Serve locally
php -S localhost:8080 -t backend/

# Admin panel
open http://localhost:8080/admin/login.php
```

Default admin credentials: `admin@laundry.com` / `admin123`

### Flutter Apps

1. Update `AppConfig.baseUrl` in `lib/utils/constants.dart` for both apps
2. Run `flutter pub get` in each app folder
3. `flutter run` or `flutter build apk --release`

### Database

SQLite DB is auto-created at `backend/database/laundry.db` on first request. Ensure the directory is writable:

```bash
chmod 755 backend/database/
```

## Live Demo

- Admin Panel: [https://laundry.hellosravan.in/admin](https://laundry.hellosravan.in/admin)
- API Base: [https://laundry.hellosravan.in/api](https://laundry.hellosravan.in/api)

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login.php` | — | Login |
| POST | `/api/auth/register.php` | — | Register |
| GET | `/api/customer/services.php` | — | List services |
| GET/POST | `/api/customer/orders.php` | Customer | Orders |
| GET/PUT | `/api/delivery/orders.php` | Rider | Assigned orders |
| GET/POST/PUT/DELETE | `/api/admin/orders.php` | Admin | Manage orders |
| GET/POST/PUT/DELETE | `/api/admin/users.php` | Admin | Manage users |

## Order Status Flow

`pending` → `assigned` → `picked_up` → `washing` → `ready` → `out_for_delivery` → `delivered`
