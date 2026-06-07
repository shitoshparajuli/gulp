# CLAUDE.md

Context for picking up gulp from a cold start. Read this first.

## What gulp is

iOS app for rating dishes 1–10 at restaurants you visit. Personal log first, social later. Solo dev project. Built in Swift/SwiftUI on iOS 26 with Xcode 26, backed by Supabase.

Backend is in `supabase/` (CLI-linked, project ref `rheqemyqgahwstphguxn`). iOS app in `ios/gulp/`.

## Architecture

**Stack**
- SwiftUI + `@Observable` (no Combine/`ObservableObject` — Xcode 26 had conformance issues with `@MainActor` + `ObservableObject`)
- Supabase Swift SDK for Postgres + Auth + Storage
- Apple MapKit (`MKLocalSearchCompleter`) for restaurant search
- Google Sign-In SDK → Supabase Auth via `signInWithIdToken`

**State pattern**
- ViewModels are `@MainActor @Observable final class` — held by views as `@State`
- Pass to children via `@Bindable var foo: FooViewModel`
- Free `supabase` global instance from `Services/SupabaseClient.swift`

**Data layer (repositories)**
- ViewModels do **not** call `supabase.from(...)` directly. All table access goes through one repository per table in `Services/`: `RatingsRepository`, `DishesRepository`, `RestaurantsRepository`, `DishPhotosRepository`, `FollowsRepository`, `ProfilesRepository`. Each is a stateless `struct` with a `.shared` singleton.
- The repository owns the column list / nested-select string and the decode types, so screens can't drift apart. Add a new query as a method there, don't inline a new `supabase.from(...)` in a ViewModel.
- `Session.currentUserID()` replaces scattered `supabase.auth.session.user.id`.

**Folder structure**
- `App/` — entry point, app root, theming
- `Auth/` — login flow
- `Features/<Name>/` — one folder per feature, each has its own ViewModel + Views
- `Services/` — external clients (Supabase, MapKit search) + the repository layer
- Files inside `gulp/` are auto-included via Xcode 26's `PBXFileSystemSynchronizedRootGroup`. **You don't add files to the project**, just drop them into the folder. Dragging in Xcode doesn't work and is unnecessary.

## Design language

Forced dark mode, premium aesthetic, score-as-hero. All tokens in `App/Theme.swift`:

- `Theme.background` near-black, `Theme.surface` and `surfaceElevated` for cards/chips
- `Theme.accent` warm coral (the only accent color)
- `Theme.textPrimary/Secondary/Tertiary` (white at 1.0 / 0.6 / 0.35)
- `Theme.hairline` (white at 0.06) for borders and dividers
- `scoreColor(_:)` and `scoreGradient(_:)` — earth-tone palette (sage → olive → mustard → ochre → terracotta → wine) that maps green-to-red intuitively without looking sporty
- `.elevatedCard(cornerRadius:)` modifier for 3D cards: surface gradient (light top, dark bottom) + gradient stroke that brightens the top edge + layered drop shadows. Use this on every card.
- `PressableButtonStyle` (in `RatingsView.swift`) for tap feedback on rows

**Conventions**
- Every screen: `.preferredColorScheme(.dark)`
- Cards: continuous corner radius 16–20, `.elevatedCard()`
- Restaurant/brand names: uppercase, bold, tracked 0.5–1.0
- Section labels (NOTES, AVG, OUT OF 10, EDIT): all caps, heavy, tracked 1.0+, `textTertiary`
- Score is the hero: rounded SF Pro, large, colored via `scoreGradient`, often with `shadow` halo
- Sheets: `.presentationBackground(Theme.background)`, custom capsule drag handle (not the default indicator), medium + large detents
- Hero scores 80–140pt with colored shadow halo
- Avoid system `Color(.secondarySystemGroupedBackground)` etc — always use Theme tokens

See memory file `feedback_ui_quality` and `project_design_language` for non-negotiable UI bar.

## Database

Schema lives in the remote Supabase project. The migration in `supabase/migrations/` is a placeholder — to dump the live schema you need Docker (`supabase db pull`).

**Tables (public schema)**
- `restaurants(id, place_id, name, latitude, longitude, address, added_by, created_at)` — `place_id` is the MapKit identifier, used for upsert/dedup
- `dishes(id, restaurant_id, display_name, normalized_name, cuisine, added_by, created_at)` — shared across users
- `ratings(id, user_id, dish_id, score smallint, notes, photo_path, created_at, updated_at, deleted_at)` — score is 1–10, soft-deleted via `deleted_at`
- `profiles(id, username citext, display_name, avatar_url, created_at)` — auto-created by `handle_new_user` trigger on auth.users insert
- `follows(follower_id, followee_id, created_at)` — not used yet

**RLS**: enabled. The Swift SDK attaches the session JWT automatically, so `auth.uid()` is available in policies.

**Querying nested data**: PostgREST nested select with the foreign-key table name. Example:
```swift
.select("id, score, notes, dishes(id, display_name, restaurants(id, name, address))")
```
Maps to Decodable structs where the nested keys use the FK table name (`dishes`, `restaurants`).

**Soft delete**: never hard-delete a rating. Soft-delete goes through `RatingsRepository.softDelete(ids:)`, which calls the `soft_delete_ratings(uuid[])` **SECURITY DEFINER** RPC (migration `20260606160000`). A direct `UPDATE ... SET deleted_at` from the client silently fails on this project (same `user_id = auth.uid()` RLS issue the INSERT hotfix worked around) — the function bypasses RLS but still enforces ownership via `auth.uid()` and returns the affected-row count. Reads filter `where row.deletedAt == nil` client-side as a belt-and-suspenders (the `ratings_select_active` policy already hides deleted rows).

## Storage

Bucket: `dish-photos`. Public read, authenticated user-scoped write.

- Path convention: `<auth.uid()>/<uuid>.jpg`
- Policies: insert/update/delete restricted to `(storage.foldername(name))[1] = auth.uid()::text`, select is public
- Public URL helper: `dishPhotoURL(path:)` in `Features/Ratings/RatingsViewModel.swift`
- Upload uses `supabase.storage.from("dish-photos").upload(path, data:, options:)` with `FileOptions(contentType: "image/jpeg")`

## Add-rating flow (the most complex piece)

`AddRatingView` takes an `AddRatingMode`:
- `.newFromScratch` — Restaurant picker → Photo → Dish → Score
- `.addToRestaurant(RestaurantResponse)` — Photo → Dish → Score (skip restaurant picker, dishes pre-loaded)
- `.editRating(RatingResponse)` — Score (with photo edit strip at top, no restaurant/dish change)

All three modes share `AddRatingViewModel`. Key methods:
- `selectRestaurant(_ place: PlaceResult)` — upserts to `restaurants` (matches on `place_id`), loads dishes
- `selectExistingDish(_ dish: DishOption)` — sets `pickedDish` AND checks if the user already has an active rating for this dish; if so, **switches the flow into edit mode** by setting `editingRatingId`, prefilling score/notes/photoPath. Save then updates instead of inserts.
- `save()` — branches on `editingRatingId`: update existing rating, or insert (creating the dish if it's new). Uploads `selectedPhoto` to Storage first if present, otherwise keeps `existingPhotoPath`.

## Search (two scopes, one mental model)

Both scopes share the `SearchField` component (`Features/Search/SearchField.swift`):

- **My Ratings filter** (Profile → `RatingsView`): a pure **client-side** filter, no network. `RatingsViewModel.searchText` drives a `filteredGroups` computed over the already-loaded `groups` — a restaurant survives if its name matches (keeps all dishes) or it has matching dishes (keeps just those). Same component also filters other users' lists in read-only mode.
- **Global search** (Home → `Features/Search/SearchView` + `SearchViewModel`): a dedicated full-screen page pushed from a tappable bar on `HomeView`, `.hidesAppTabBar()`. Searches **everything** — dishes ranked by community average + restaurants by name — via two parallel queries, debounced 250ms with `.task(id: searchText)` (cancellation during the sleep is the debounce). Results push into `DishDetailView` / `RestaurantDetailView`. Scope is dishes + restaurants; no people yet, but `SearchView` is laid out to drop in a third section.

**Repository methods** (don't inline these in a VM):
- `DishesRepository.search(matching:limit:)` → `[DishSearchRow]` (dish + its restaurant + nested ratings). `SearchViewModel.ranked(_:)` aggregates community avg/count and sorts rated-first by avg, reusing `RestaurantDetailViewModel`'s logic. The UI model `DishSearchResult` lives in `Features/Search/SearchModels.swift`.
- `RestaurantsRepository.search(matching:limit:)` → `[RestaurantResponse]`.

**`ilike` gotcha**: supabase-swift's `.ilike(col, pattern:)` takes the SQL `%…%` wildcard (**not** PostgREST's `*`). User input is sanitized through `String.ilikeEscaped` (`Services/String+ILike.swift`), which strips `% _ , ( ) *` so text matches literally and an all-wildcard query can't match everything. `SearchViewModel` also guards `q.ilikeEscaped.count >= 2`.

## Build & test

```bash
xcodebuild -project ios/gulp/gulp.xcodeproj -scheme gulp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build
```

There's no test target. After feature work, smoke-test the build and tell the user to Cmd+R to test the UI on the simulator — UI correctness is not something the build verifies.

## Gotchas

- **Xcode 26 + UIKit editor errors**: if the editor (not the build) complains about UIKit, check that macOS is removed from Supported Destinations on the target. Don't add `#if canImport(UIKit)` guards — the user vetoed that pattern.
- **`PBXFileSystemSynchronizedRootGroup`**: files auto-sync from disk. "Add Files to..." dialog greys things out because they're already in the project. Don't try to drag files; just write them to the right folder.
- **No `Info.plist` was generated initially** — modern Xcode embeds Info keys in pbxproj. We later added an `Info.plist` for the Google URL scheme + `GIDClientID`. It's listed as a membership exception in pbxproj.
- **`ObservableObject` + `@MainActor`**: the conformance breaks in Xcode 26 in certain compilation orders. Use `@Observable` from the `Observation` framework everywhere instead.
- **`Slider` + `.contentTransition(.numericText(value:))`** needs the integer score, not the slider's Double, otherwise animation lags.
- **Score color/gradient are global functions** (not methods/extensions) in `Theme.swift`. Don't redeclare them in views.
- **`scoreColor` was redeclared once and broke the build** — search the project before adding a helper.
- **Swipe actions don't work in `ScrollView`/`LazyVStack`** (List only). We use `.contextMenu` (long-press) for per-row Edit/Delete instead.
- **MapKit `MKMapItem.identifier`** is iOS 18+. We fall back to `name|lat|lng` if it's missing, but on iOS 26 it should always be there.
- **Address from MapKit** is composed from `thoroughfare + locality + administrativeArea` (not the verbose `placemark.title`).

## Available memory

The harness has memory files at `~/.claude/projects/-Users-shitoshparajuli-projects-gulp/memory/`:
- `feedback_ui_quality.md` — user's bar for UI quality
- `project_design_language.md` — the design tokens and patterns

Always check `MEMORY.md` for the index when you start.
