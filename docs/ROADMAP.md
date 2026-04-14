# Airmates iOS App — Roadmap

Last updated: 2026-04-14

The native iOS companion to the Airmates flying club management platform. Swift 5 / SwiftUI / iOS 17+. Consumes the same backend API as the web app at `airmatesacy.com`. Distributed via TestFlight, future App Store release.

---

## Current Status

**TestFlight build**: `1.0 (5)` — latest shipped in this session, available to the internal DA testing group.

**Next milestone**: Native in-app Stripe payments (see [PAYMENTS-PLAN.md](./PAYMENTS-PLAN.md)).

---

## Shipped in This Session (Apr 13-14, 2026)

Between session start and TestFlight build `1.0 (5)`, the following fixes shipped:

### Schedule

- [x] **Booking colors match the web exactly** — `BookingRowV2` uses the same priority logic as the web's `bColor()` function in `airmateswebsite2026/src/components/AppShell.tsx:7518`:
  1. Status overrides: `MISSED`=red, `CANCELLED`=gray, `STANDBY`=yellow (`#eab308`)
  2. `MAINTENANCE` type=black
  3. User's own bookings=amber (`#d97706` bar, `#92400e` text)
  4. Per-aircraft custom `bookingColor` field
  5. Aircraft type fallback: `182`=green, `172`=gray, default=blue
  - Color logic lives in `AirmatesApp/Extensions/Color+Brand.swift` as `Color.bookingColor(type:status:aircraftType:bookingColor:isMine:)`
  - Type badge colors match web Badge variants: SOLO=green `#15803d`, DUAL=blue `#1d4ed8`, MAINTENANCE=slate `#334155`

- [x] **"YOU" badge on own bookings** — `BookingRowV2` compares `booking.memberId` against `appState.currentUser?.id` and shows a small amber `YOU` badge when they match, next to the aircraft name.

- [x] **List view chronological sort** — Was sorting section headers alphabetically by display string, so "Friday, Apr 3" appeared after "Friday, Apr 17". Replaced the `[String: [Booking]]` dictionary with a date-keyed `[BookingGroup]` array in `ScheduleViewV2.sortedGroupedBookings`.

### Today

- [x] **Personal balance fix** — `TodayView` was showing `dashboardData.unpaidTotal` from `/api/dashboard`, which is an **admin-only org-wide total** ($130 across all members for Darren). Now uses `viewModel.personalBalance` from `/api/my-account`, which was already being fetched in `TodayViewModel.loadAll()` but never wired to the UI.

- [x] **Tappable balance card** — `BalanceCard` on Today is now wrapped in a `NavigationLink` to `MyAccountView`, with a chevron indicator and "tap to pay" hint when a balance is owed.

- [x] **`-$0.00` edge case** — Floating point `-0.0001` from the balance endpoint was showing as "-$0.00 Amount Due" in red with a bogus Pay Balance button. Both `BalanceCard.swift` and `MyAccountView.swift` now treat `abs(balance) < 0.01` as zero ("Paid Up", primary color, no pay button).

### Forum

- [x] **Tappable URLs in posts/replies** — Added `LinkedText` view in `AirmatesApp/Extensions/String+HTML.swift` that regex-detects `https?://` URLs and renders them as tappable Markdown links in post and reply content. Previously URLs rendered as plain gray text.

### App

- [x] **App icon restored** — Build 3 accidentally shipped with a solid blue gradient because `AppIcon.appiconset/Contents.json` was empty. Build 4 restored the original 1024×1024 icon from git stash, regenerated all 18 size variants via `sips`, and wrote a clean `Contents.json`.

- [x] **TestFlight upload pipeline** — Created `ExportOptions.plist` for app-store-connect destination. Unlocked the Mac Mini keychain. Archive + export + upload runs via `xcodebuild` over SSH. Builds 3, 4, and 5 all processed successfully. Build numbers bumped via `sed` on `project.yml` before each archive.

---

## Next Milestone: Native In-App Payments

**Status**: Planned, not yet implemented.

The current "Pay Balance" button opens `airmatesacy.com/{slug}#my-account` in the system Safari browser. This is unreliable because members have to sign in again in Safari, and the hash-routed page depends on session cookies that `SFSafariViewController` can't share. The earlier `/account` path returned 404.

**Goal**: Members complete the entire payment flow — amount entry, fee preview, card/ACH input, 3D Secure, confirmation — without ever leaving the app.

**Approach**: Integrate Stripe's prebuilt `PaymentSheet` iOS SDK. The web backend already has a complete Stripe Connect pipeline (`/api/stripe/create-payment-intent`, `payment-methods`, `preview-fee`, `cancel-payment-intent`, `record-pending-payment`) — the iOS client only needs a thin pre-sheet for amount/fee display and then hands off to PaymentSheet.

**Full technical spec**: See [PAYMENTS-PLAN.md](./PAYMENTS-PLAN.md).

**Implementation phases** (each a separate commit for independent rollback):

- [ ] **Phase A0**: `curl` verify every Stripe endpoint before writing Swift models
- [ ] **Phase A**: Add `stripe-ios 25.11.0` SPM dep, `StripeService`, `StripeModels`, app launch config
- [ ] **Phase B**: `PaymentViewModel` with error mapping
- [ ] **Phase C**: `PayBalanceSheet`, `PaymentSuccessView`, `SavedPaymentMethodRow`, wire into `MyAccountView`
- [ ] **Phase D**: Roadmap docs (this file + PAYMENTS-PLAN.md) ← **COMPLETE**

**Blockers**:
- Need `pk_test_...` key from Stripe Dashboard to paste into `AppConstants.swift`
- URL scheme migration in `project.yml` (switching from `GENERATE_INFOPLIST_FILE: YES` to explicit `Info.plist`) needs verification that Face ID description + orientations still work

---

## Phase 2 Backlog (post-payments)

Deferred features that are scoped but not yet planned in detail:

- [ ] **Apple Pay** — Register merchant ID with Apple, generate CSR in Stripe Dashboard, add `com.apple.developer.in-app-payments` entitlement, set `config.applePay = .init(merchantId:...)` in PaymentSheet config. One line of code once infrastructure is in place.

- [ ] **Customer Session for saved methods in PaymentSheet** — Backend change: have `/api/stripe/create-payment-intent` also return a `customer_session_client_secret` or ephemeral key. Then pass `customerConfiguration` to PaymentSheet so Stripe's UI shows saved cards directly instead of our custom pre-sheet list.

- [ ] **Auto-pay toggle** — User model already has `autoPayEnabled`. Build a settings toggle in MyAccountView that PATCHes `/api/stripe/payment-methods`.

- [ ] **CustomerSheet for standalone payment method management** — Let users add/remove saved cards and bank accounts outside of a specific payment flow.

- [ ] **Push notifications** — Scaffolding already exists in `Services/NotificationService.swift` and `aps-environment` entitlement is configured. Needs server-side device token registration and notification payload design. Use cases: booking reminders, maintenance alerts, payment confirmations, forum @mentions.

- [ ] **Widget / Lock Screen widget** — Upcoming flight countdown, aircraft availability glance. Separate widget extension target (deferred due to config risk).

- [ ] **Offline-first for Today view** — `CacheService` is in place for weather. Extend to bookings, fleet status, and announcements so the Today tab works without network.

- [ ] **Biometric re-auth for sensitive actions** — `BiometricService` exists. Wire into payment confirmation, profile edits, and check-out flows.

---

## Known Issues / Tech Debt

- **Swift compiler warning** at `ViewModels/TodayViewModel.swift:72` — `personalBalance = accountData.balance ?? 0` uses `??` on a non-optional `Double`. Cosmetic; fix during Phase A cleanup.
- **`APIClient.swift` warning** — Capture of `self` in `@Sendable` closure at `APIClient.swift:118`. Non-blocking but should be fixed with `[weak self]` or by making `APIClient` Sendable.
- **`AppConstants.baseURL`** — Set to `https://airmatesacy.com` but unused. `APIClient` hardcodes `https://airmateswebsite2026.vercel.app` instead. Either consolidate or document why both exist.
- **Build number / git drift** — `CURRENT_PROJECT_VERSION` in committed `project.yml` lags the values used for TestFlight archives. Sed bumps during archive runs are not committed back to git. Consider a script or commit hook.

---

## Architecture Quick Reference

- **Framework**: SwiftUI + `@Observable` ViewModels + async/await
- **Networking**: `APIClient` singleton wraps `URLSession`, attaches JWT Bearer from `KeychainManager`, auto-retries 401 via `requestWithRetry()` calling `AuthService.refreshToken()`
- **State**: `AppState` (in `Environment`) holds `currentUser` + `isAuthenticated`. ViewModels own per-feature state.
- **Auth**: Mobile auth endpoint at `/api/auth/mobile` returns 30-day JWT. Token stored in Keychain with key `com.airmates.jwt`.
- **Build**: XcodeGen generates `AirmatesApp.xcodeproj` from `project.yml`. CI at `.github/workflows/ios-build.yml`.
- **Distribution**: TestFlight via `xcodebuild archive` + `xcodebuild -exportArchive` with `ExportOptions.plist` (method: `app-store-connect`, destination: `upload`). Team `V34FFS732V`. Bundle `com.airmates.app`.
- **Testing**: Simulator `iPhone 17 Pro` on iOS 26.4 (Xcode 26.4). All in-app testing uses **Skyhaven Aero Club** test tenant, never the live ACY tenant.

---

## Pinned Rules (never skip)

1. **Swift 5 only** — Do NOT bump to Swift 6. Strict concurrency breaks all existing singletons (`APIClient.shared`, `AuthService.shared`, `KeychainManager.shared`).
2. **iOS 17 target** — Don't bump minimum; fine to use iOS 18+ APIs inside `if #available(iOS 18.0, *)` blocks.
3. **New model fields must be Optional** — Server can add fields without breaking decoding.
4. **Match the web exactly** — Colors, behavior, flows. Always read the web source first before inventing mobile UX.
5. **Test tenant only** — All testing runs against Skyhaven Aero Club. Never test payment flows on the live ACY tenant.
6. **No backend guesses** — Curl every endpoint before writing a Codable model.
