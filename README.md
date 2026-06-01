# gulp

A personal food rating app for iOS. Rate dishes 1–10 at the places you actually eat, keep notes, and remember what you loved.

## Stack

- **iOS app**: SwiftUI, Swift, iOS 26+, Xcode 26
- **Auth**: Sign in with Google → Supabase Auth (id-token flow)
- **Backend**: Supabase (Postgres + Storage + RLS)
- **Maps**: Apple MapKit (`MKLocalSearchCompleter`) for finding restaurants

## Repo layout

```
gulp/
├── ios/gulp/            Xcode project
│   └── gulp/
│       ├── App/         entry point (gulpApp), AppRoot, custom tab bar, Theme tokens
│       ├── Auth/        AuthViewModel + LoginView
│       ├── Features/
│       │   ├── Ratings/      list + restaurant cards + dish detail sheet
│       │   ├── AddRating/    multi-step add/edit flow (MapKit search → photo → dish → score)
│       │   └── Profile/      placeholder profile + sign-out
│       └── Services/    SupabaseClient, RestaurantSearchService (MapKit wrapper)
└── supabase/            CLI project linked to remote (project ref rheqemyqgahwstphguxn)
    ├── config.toml
    └── migrations/
```

## Setup from a fresh clone

```bash
# 1. Install Supabase CLI
brew install supabase/tap/supabase
supabase login

# 2. Link the CLI to the remote project
cd supabase && supabase link --project-ref rheqemyqgahwstphguxn

# 3. Open Xcode and build
open ios/gulp/gulp.xcodeproj
# Run on iPhone 17 simulator (Cmd+R)
```

You'll need:
- A Google OAuth iOS client whose bundle ID matches the app (`com.shitosh.gulp`)
- Supabase URL + anon key wired into `ios/gulp/gulp/Services/SupabaseClient.swift`
- `Info.plist` URL scheme = reversed Google client ID
- `GIDClientID` in `Info.plist` = your Google iOS OAuth client ID
- "Skip nonce check" enabled in Supabase → Auth → Providers → Google

## What's built

- Sign in with Google → Supabase session
- Ratings tab with restaurant cards (avg score, dishes, score badges)
- Dish detail sheet (photo, score hero, notes)
- Tap **+** in the tab bar to add a rating: restaurant → photo → dish → score
- Long-press a dish row → Edit / Delete
- Card menu (⋯) → Add a dish to this restaurant / Remove from list
- Picking an "already ordered" dish in the create flow switches to edit mode automatically
- Soft delete via `ratings.deleted_at`

## Conventions

- Dark mode is forced (`.preferredColorScheme(.dark)`) on every screen
- All styling via tokens in `App/Theme.swift` — never use system grouped backgrounds
- See [CLAUDE.md](./CLAUDE.md) for the design language and architecture in detail
