# folio — Expense Tracker

Minimal monochrome expense tracker: **Flutter** mobile app + **Vercel** serverless API + **MongoDB Atlas**.

## Stack

| Layer | Tech |
|-------|------|
| Mobile | Flutter, Riverpod, go_router, fl_chart |
| API | Vercel serverless (TypeScript) |
| DB / Auth | MongoDB Atlas + JWT (bcrypt passwords) |

## Project structure

```
├── api/           # Vercel serverless handlers
├── mobile/        # Flutter app (folio)
├── vercel.json
└── package.json
```

## Setup

### 1. MongoDB Atlas

1. Use your cluster: `mongodb+srv://chacko:<db_password>@cluster.ftqhfps.mongodb.net/`
2. Create database `folio` (append to URI or it auto-creates on first write)
3. Network Access → allow your IP (or `0.0.0.0/0` for dev)
4. Categories are auto-seeded on first API request

### 2. Local API

```bash
cd "D:\Expense Tracker"
copy .env.example .env
```

Edit `.env`:
```
MONGODB_URI=mongodb+srv://chacko:YOUR_PASSWORD@cluster.ftqhfps.mongodb.net/folio?retryWrites=true&w=majority
JWT_SECRET=some-long-random-secret-string
```

```bash
npm install
npx vercel dev
```

API runs at `http://localhost:3000`.

### 3. Flutter (phone / emulator)

```bash
cd mobile
flutter pub get

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical phone (same Wi-Fi, use your PC LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000
```

## API endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/signup` | Create account → returns JWT |
| POST | `/api/auth/login` | Login → returns JWT |
| GET/POST | `/api/expenses` | List / create transactions |
| PATCH/DELETE | `/api/expenses/[id]` | Update / delete |
| GET/POST | `/api/categories` | List / create categories |
| GET/POST | `/api/budgets` | List / create budgets |
| GET | `/api/analytics/summary` | Balance, trends, category breakdown |
| GET/PATCH | `/api/profile` | User profile / currency |

All routes except auth require `Authorization: Bearer <jwt>`.

## Env vars

| Variable | Where | Description |
|----------|-------|-------------|
| `MONGODB_URI` | Vercel / `.env` | Atlas connection string |
| `JWT_SECRET` | Vercel / `.env` | Signs auth tokens — keep secret |
| `API_BASE_URL` | Flutter `--dart-define` | API URL (local or deployed) |

## Test without deploying

1. `npx vercel dev` — local API, no Vercel deploy
2. MongoDB Atlas free tier — cloud DB only, no app hosting
3. `flutter run` on emulator/phone

```bash
# Quick API test after signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@test.com\",\"password\":\"secret12\"}"
```

## Deploy API (optional)

```bash
npx vercel
# Add MONGODB_URI + JWT_SECRET in Vercel dashboard
```

Then point Flutter at `https://your-app.vercel.app`.
