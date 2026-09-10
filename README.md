# Make Bolão Great Again
[![CI](https://github.com/dserenini/WC-GuessingGame/actions/workflows/ci.yml/badge.svg)](https://github.com/dserenini/WC-GuessingGame/actions/workflows/ci.yml)

A Flutter Web PWA for predicting World Cup 2026 group-stage scores with friends.

---

## 🚀 Quick Start

### 1. Set up Supabase

See the [Supabase Setup Guide](implementation_plan.md) for step-by-step instructions.
After creating your project:

1. Open `lib/core/supabase_config.dart` and paste your URL + anon key.
2. Run `supabase/schema.sql` in the Supabase SQL Editor.
3. Run `supabase/seed.sql` to populate all 48 teams and 72 matches.

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Run the app locally

```bash
flutter run -d chrome
```

### 4. Build & deploy (PWA)

```bash
flutter build web --release
# Then deploy the build/web/ folder to any static host (Netlify, Vercel, Firebase Hosting, etc.)
```

---

## 📁 Project Structure

```
lib/
├── core/               # constants, theme, router, supabase config
├── l10n/               # PT / EN / IT .arb files
├── services/           # master_data_service.dart (manual sheet sync)
├── shared/
│   ├── models/         # Team, Match, Bet, League, RankingEntry
│   ├── providers/      # Theme + Locale providers
│   └── widgets/        # AppDrawer, FlagAvatar, ScoreBottomSheet
└── features/
    ├── auth/           # Login + SignUp screen
    ├── groups/         # Group screen, StandingsTable, MatchCard
    ├── ranking/        # Real-time global ranking
    ├── leagues/        # Private leagues (create + join)
    ├── chaos/          # Agent of Chaos service
    ├── admin/          # Admin panel (match override)
    └── settings/       # Theme, language, chaos config
```

---

## ⚙️ Configuration Checklist

| Item | File | Status |
|---|---|---|
| Supabase URL | `lib/core/supabase_config.dart` | ⬜ TODO |
| Supabase Anon Key | `lib/core/supabase_config.dart` | ⬜ TODO |
| Admin UUIDs | `lib/core/constants.dart` → `kAdminUids` | ⬜ TODO |
| Admin seed | `supabase/seed.sql` (uncomment last block) | ⬜ TODO |

---

## 🎲 Agent of Chaos Rules

- **Full Random** (🎲 button in AppBar): fills all *empty* bets with random scores
- **Guided Random**:
  - Tap a **team flag** → random win for that team
  - Tap the **X** between scores → random draw
- Alert shown if either score > 20 goals ("Are you serious? 😱")

## 🏆 Scoring Rules

| Outcome | Points |
|---|---|
| Exact score | 3 pts |
| Correct winner / draw | 1 pt |
| Wrong | 0 pts |

## 🔒 Bet Deadline

All bets are locked after **June 10, 2026 at 23:59 GMT-3**.
Change `kBetDeadline` in `lib/core/constants.dart` if needed.

---

## 📱 PWA — Add to Home Screen

1. Open the deployed app in **Chrome on Android**.
2. Tap the menu (⋮) → **"Add to Home Screen"**.
3. The app will behave like a native mobile app.

---

## 🌍 i18n

Supported languages: **Português 🇧🇷**, **English 🇺🇸**, **Italiano 🇮🇹**  
Switch language in Settings.

Source files: `lib/l10n/app_pt.arb`, `app_en.arb`, `app_it.arb`

---

## 👑 Admin Access

Three designated admin UIDs can:
- Override match scores and status (scheduled/live/finished)
- Access the Admin Panel from the drawer (visible only to admins)

Admin UIDs are seeded via `supabase/seed.sql` (commented block at the bottom).
