# In-App Payments Technical Spec

**Status**: Planned, approved 2026-04-14. Not yet implemented.

**Source of truth for this plan**: `C:\Users\Darren\.claude\plans\bright-tickling-crab.md` (approved by Darren 2026-04-14). This document is the trimmed, committed-to-repo version for future reference.

---

## Goal

Members complete their balance payment — amount entry, fee preview, card/ACH input, 3D Secure, confirmation — entirely inside the iOS app. No more Safari redirects.

## Approach

Use Stripe's prebuilt `PaymentSheet` (iOS SDK). Do not build custom card input UI. Do not use `PaymentSheet.FlowController`.

**Two-screen flow**:
1. **Custom SwiftUI pre-sheet** (`PayBalanceSheet.swift`) — amount entry, fee preview, saved method selection. This exists because PaymentSheet can't show the "you pay $103.20, club receives $100, fee $3.20" breakdown.
2. **Stripe `PaymentSheet`** — card/ACH entry, 3D Secure, confirmation. Presented after the user commits to an amount.

All backend endpoints already exist. No backend changes required.

---

## Backend Contract

All endpoints are under `https://airmateswebsite2026.vercel.app/api/stripe/` and require JWT Bearer auth (handled automatically by `APIClient.shared`).

### `GET /api/stripe/payment-methods`

Lists saved payment methods for the current user.

**Response**:
```json
{
  "methods": [
    {
      "id": "pm_xxx",
      "type": "card" | "us_bank_account" | "link",
      "brand": "visa" | "Bank Name" | null,
      "last4": "4242" | null,
      "isDefault": true,
      "expMonth": 12,
      "expYear": 2028,
      "accountType": "checking" | "savings" | null
    }
  ],
  "stripeEnabled": true,
  "defaultPaymentMethodId": "pm_xxx" | null,
  "autoPayEnabled": false,
  "payment_method_zelle_handle": "club@example.com" | null,
  "payment_method_venmo_handle": "@club" | null
}
```

**Gotchas**:
- `defaultPaymentMethodId` and `autoPayEnabled` are **omitted** when Stripe is disabled for the org → Swift model fields must be `Optional`.
- `last4` and `brand` can be `null` for Stripe Link and other unsupported method types → must be `Optional`.
- `payment_method_zelle_handle` / `payment_method_venmo_handle` are raw snake_case in the JSON → must use `CodingKeys` mapping.

### `GET /api/stripe/preview-fee?desired_net_cents=10000&payment_method_type=card`

Calculates the inflated charge amount to cover Stripe's processing fee.

**Query params**: `desired_net_cents` (Int, required), `payment_method_type` (String, `"card"` or `"us_bank_account"`).

**Response**:
```json
{
  "desiredNetCents": 10000,
  "chargeAmountCents": 10320,
  "feeCents": 320,
  "paymentMethodType": "card"
}
```

**Fee formulas** (mirror for client-side estimation only; always trust backend response):
- Card: `charge = ceil((desired_net + 30) / (1 - 0.029))` → 2.9% + $0.30
- ACH: `charge = ceil(desired_net / (1 - 0.008))` capped at `desired_net + $5` → 0.8% max $5

This endpoint is **public** (no auth required) and is safe to call on every amount change.

### `POST /api/stripe/create-payment-intent`

Creates a Stripe PaymentIntent on the platform account with `transfer_data` routing funds to the club's Connected Express account.

**Request body** (snake_case):
```json
{
  "desired_net_cents": 10000,
  "payment_method_type": "card",
  "payment_method_id": "pm_xxx"
}
```

`payment_method_id` is optional — omit to let PaymentSheet collect a fresh card/bank.

**Response**:
```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "paymentIntentId": "pi_xxx",
  "chargeAmountCents": 10320,
  "desiredNetCents": 10000,
  "feeCents": 320
}
```

**Gotcha**: The backend validates `Number.isInteger(desired_net_cents)` at `create-payment-intent/route.ts:34`. Use `Int(round(dollars * 100))` in Swift — never encode a `Double` to `desired_net_cents`.

### `POST /api/stripe/cancel-payment-intent`

Cancels an in-flight PaymentIntent that the user abandoned. Mirrors what the web does at `AppShell.tsx:1721` on modal dismiss.

**Request body**:
```json
{ "paymentIntentId": "pi_xxx" }
```

**Gotcha**: Must be called from the iOS client on:
- Swipe-to-dismiss of `PayBalanceSheet` (if a PI was created but not confirmed)
- `.canceled` result from Stripe's PaymentSheet
- Scene going to background with an open PI (best-effort; swallow errors)

Without this, abandoned PaymentIntents accumulate in Stripe and the backend has no way to clean them up.

### `POST /api/stripe/record-pending-payment`

Records an ACH payment as `PENDING` immediately (before the webhook fires), so the user's ledger shows "Processing" in real time.

**Request body**:
```json
{
  "paymentIntentId": "pi_xxx",
  "amount": 100.00
}
```

**Gotcha**: The backend **requires both** `paymentIntentId` and `amount`. The `amount` is in **dollars** (not cents) — `parseFloat(payAmt)` on the web (`AppShell.tsx:2250`). Sending only `paymentIntentId` returns a 400.

Call this only after PaymentSheet returns `.completed` with an ACH payment method.

---

## iOS Client Architecture

### New files

```
AirmatesApp/
├── Models/
│   └── StripeModels.swift            # Codable request/response models
├── Services/
│   └── StripeService.swift           # Wraps APIClient for all 5 endpoints
├── ViewModels/
│   └── PaymentViewModel.swift        # @MainActor @Observable
└── Views/Account/
    ├── PayBalanceSheet.swift         # Pre-sheet with amount/fee/method
    ├── PaymentSuccessView.swift      # Post-payment confirmation
    └── SavedPaymentMethodRow.swift   # Reusable list row
```

### Modified files

- **`project.yml`** — Add `stripe-ios 25.11.0` SPM package, migrate from `GENERATE_INFOPLIST_FILE: YES` to explicit `Info.plist` with `CFBundleURLTypes` for the `airmates://` scheme, bump `CURRENT_PROJECT_VERSION`.
- **`App/AirmatesApp.swift`** — `import StripePaymentSheet`, call `StripeService.shared.configure()` in `.task`, add `.onOpenURL { _ = StripeAPI.handleURLCallback(with: $0) }`.
- **`App/AppConstants.swift`** — Add `stripePublishableKey` and `stripeReturnURL = "airmates://stripe-redirect"`.
- **`Views/Account/MyAccountView.swift`** — Replace `openURL` action with `.sheet` presenting `PayBalanceSheet`. Remove `@Environment(\.openURL)` if unused elsewhere.

### Key model requirements

```swift
// All fields optional unless explicitly verified non-null
struct SavedPaymentMethod: Codable, Identifiable {
    let id: String
    let type: String
    let brand: String?        // null for Stripe Link
    let last4: String?        // null for Stripe Link
    let isDefault: Bool
    let expMonth: Int?
    let expYear: Int?
    let accountType: String?
}

struct PaymentMethodsResponse: Codable {
    let methods: [SavedPaymentMethod]
    let stripeEnabled: Bool
    let defaultPaymentMethodId: String?  // omitted when Stripe disabled
    let autoPayEnabled: Bool?            // omitted when Stripe disabled
    let paymentMethodZelleHandle: String?
    let paymentMethodVenmoHandle: String?

    enum CodingKeys: String, CodingKey {
        case methods, stripeEnabled, defaultPaymentMethodId, autoPayEnabled
        case paymentMethodZelleHandle = "payment_method_zelle_handle"
        case paymentMethodVenmoHandle = "payment_method_venmo_handle"
    }
}

struct CreatePaymentIntentBody: Encodable {
    let desiredNetCents: Int
    let paymentMethodType: String
    let paymentMethodId: String?

    enum CodingKeys: String, CodingKey {
        case desiredNetCents = "desired_net_cents"
        case paymentMethodType = "payment_method_type"
        case paymentMethodId = "payment_method_id"
    }
}

struct RecordPendingPaymentBody: Encodable {
    let paymentIntentId: String
    let amount: Double  // dollars, not cents
}
```

**Do NOT** set `APIClient.encoder.keyEncodingStrategy = .convertToSnakeCase` globally — it would break every existing model. Per-model `CodingKeys` is the lower-blast-radius fix.

### PaymentSheet configuration

```swift
var config = PaymentSheet.Configuration()
config.merchantDisplayName = "Airmates"
config.allowsDelayedPaymentMethods = true  // enables ACH
config.returnURL = "airmates://stripe-redirect"
config.defaultBillingDetails.email = appState.currentUser?.email
config.style = .automatic  // respects dark/light mode

var appearance = PaymentSheet.Appearance()
appearance.colors.primary = UIColor(Color.brandBlue)
appearance.cornerRadius = 12
config.appearance = appearance

let paymentSheet = PaymentSheet(
    paymentIntentClientSecret: clientSecret,
    configuration: config
)
```

### Error message mapping

Don't ship raw Stripe jargon to pilots. `PaymentViewModel.errorMessage` maps:

- Network error → "No internet connection"
- `resource_missing` → "Payment method no longer valid"
- `insufficient_funds` / card declined → "Insufficient funds"
- Default → "Payment failed. Please try again or contact your treasurer."

---

## Implementation Sequence

**Four commits, independently revertable.**

### Phase A0 — Backend contract verification (before any code)

```bash
TOKEN="..."  # from Keychain
BASE="https://airmateswebsite2026.vercel.app"
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/stripe/payment-methods" | jq .
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/stripe/preview-fee?desired_net_cents=10000&payment_method_type=card" | jq .
curl -H "Authorization: Bearer $TOKEN" -X POST "$BASE/api/stripe/create-payment-intent" \
  -H "Content-Type: application/json" \
  -d '{"desired_net_cents":10000,"payment_method_type":"card"}' | jq .
```

Paste each response as a comment above the corresponding Codable struct.

### Phase A — Infrastructure (Commit 1, invisible)

1. Edit `project.yml`: add SPM package, migrate Info.plist, add URL scheme, bump build number
2. `xcodegen generate`; open in Xcode to verify
3. Build once — confirm SPM resolves and Face ID/orientations still work
4. Create `StripeModels.swift`
5. Create `StripeService.swift` with all 5 methods including `cancelPaymentIntent`
6. Paste `pk_test_...` into `AppConstants.stripePublishableKey`
7. Wire `StripeService.configure()` + `.onOpenURL` into `AirmatesApp.swift`
8. Build and commit

### Phase B — ViewModel (Commit 2, invisible)

1. Create `PaymentViewModel.swift` as `@MainActor @Observable class`
2. Implement error-message mapping
3. Smoke-test `fetchPaymentMethods()` and `previewFee()` via debug breakpoint
4. Commit

### Phase C — UI (Commit 3, the visible change)

1. Create `SavedPaymentMethodRow.swift`
2. Create `PaymentSuccessView.swift`
3. Create `PayBalanceSheet.swift` — wire up cancel-on-dismiss for every exit path
4. Modify `MyAccountView.swift` — replace Safari action with sheet presentation
5. Archive, export, upload to TestFlight
6. Commit

### Phase D — Docs (Commit 4, no code)

1. `docs/ROADMAP.md` ← **COMPLETE**
2. `docs/PAYMENTS-PLAN.md` ← **this file**

---

## Verification

**Stripe test cards** (use `pk_test_` in `AppConstants`):
- `4242 4242 4242 4242` — successful card
- `4000 0025 0000 3155` — 3D Secure challenge
- `4000 0000 0000 9995` — declined (insufficient funds)

**Manual checklist** (step 1 is non-negotiable):

1. **Log out of TestFlight if signed in as ACY. Log in as Skyhaven Aero Club.** Verify tab bar shows Skyhaven before proceeding.
2. Navigate to My Account → balance displays correctly
3. Tap "Pay Balance" → `PayBalanceSheet` slides up (NOT Safari)
4. Enter $10.00 → fee preview updates live; switch card/bank → fee changes
5. Tap "Pay $X.XX" → PaymentSheet presents natively
6. Test card `4242 4242 4242 4242` → succeeds, sheet dismisses, balance refreshes
7. Verify payment in recent transactions on both iOS and web
8. Cancel path: open PaymentSheet, swipe down → returns to pre-sheet. **Check Stripe Dashboard**: PI is `canceled`, not stuck in `requires_payment_method`.
9. 3D Secure: `4000 0025 0000 3155` → challenge sheet, confirm success
10. Decline: `4000 0000 0000 9995` → friendly error message (not raw Stripe jargon)
11. ACH: bank tab, Stripe test credentials → payment shows "Processing", webhook reconciles later
12. Background during PaymentSheet → no crash, PI completes or cancels cleanly
13. Force-quit during PaymentSheet → PI canceled on next scene-backgrounding call

**Automated**:
- `xcodebuild -project AirmatesApp.xcodeproj -scheme AirmatesApp -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4" -quiet build` must succeed
- CI workflow at `.github/workflows/ios-build.yml` must pass

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Swift 6 strict concurrency breaks singletons | Do NOT bump Swift version. Stripe iOS 25.x still supports Swift 5. |
| Stripe PI leak on abandoned payments | Call `cancelPaymentIntent` from 3 exit paths (dismiss, .canceled, background) |
| CI SPM re-download on every run | Add `actions/cache@v4` for `~/Library/Caches/org.swift.swiftpm` and SourcePackages |
| Fractional cent rounding | Always `Int(round(dollars * 100))`, never `Int(dollars * 100)` |
| Duplicate PaymentIntents from double-tap | Disable "Pay" button while `isCreatingIntent == true` |
| `@Observable` + Stripe completion closure threading | Pin `PaymentViewModel` with `@MainActor` |
| Raw Stripe jargon leaking to pilots | Error message mapping in `PaymentViewModel.errorMessage` |
| Testing hits live ACY tenant by accident | Checklist step 1: explicit Skyhaven login verification before anything else |
| Build number drift from uncommitted sed bumps | Check `project.yml` locally before archiving; bump from actual current value |

---

## Phase 2 (deferred)

- Apple Pay (merchant ID + entitlement)
- Customer Session for saved methods in PaymentSheet (requires backend change)
- Auto-pay toggle in settings
- `CustomerSheet` for standalone payment method management

---

## Rollback

If Phase C breaks TestFlight, revert `MyAccountView.swift` to the Safari-opening version. All new files (`StripeService`, `StripeModels`, `PaymentViewModel`, `PayBalanceSheet`, etc.) are additive and dormant without `MyAccountView` wiring — they can stay in place. The SPM dep on `stripe-ios` is harmless if unused.
