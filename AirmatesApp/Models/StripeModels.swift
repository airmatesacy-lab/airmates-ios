import Foundation

// MARK: - Request / Response models for /api/stripe/* endpoints
// All shapes verified field-by-field against the backend source in
// airmateswebsite2026/src/app/api/stripe/*/route.ts on 2026-04-14.

// MARK: GET /api/stripe/payment-methods
// Source: payment-methods/route.ts lines 20-89
// {
//   "methods": [
//     {
//       "id": "pm_xxx",
//       "type": "card" | "us_bank_account" | "link" | ...,
//       "isDefault": bool,
//       "supported": bool,
//       // card-only: brand, last4, expMonth, expYear
//       // us_bank_account-only: brand, last4, accountType
//       // unsupported: brand=type, last4=null, label
//     }
//   ],
//   "stripeEnabled": bool,
//   "defaultPaymentMethodId": "pm_xxx" | null,     // omitted when stripe disabled
//   "autoPayEnabled": bool,                         // omitted when stripe disabled
//   "payment_method_zelle_handle": string,          // optional org setting spread
//   "payment_method_venmo_handle": string           // optional org setting spread
// }
struct PaymentMethodsResponse: Codable {
    let methods: [SavedPaymentMethod]
    let stripeEnabled: Bool
    let defaultPaymentMethodId: String?
    let autoPayEnabled: Bool?
    let paymentMethodZelleHandle: String?
    let paymentMethodVenmoHandle: String?

    enum CodingKeys: String, CodingKey {
        case methods
        case stripeEnabled
        case defaultPaymentMethodId
        case autoPayEnabled
        case paymentMethodZelleHandle = "payment_method_zelle_handle"
        case paymentMethodVenmoHandle = "payment_method_venmo_handle"
    }
}

struct SavedPaymentMethod: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let isDefault: Bool
    let supported: Bool?
    // Optional because backend returns null for Stripe Link / unsupported types
    let brand: String?
    let last4: String?
    let expMonth: Int?
    let expYear: Int?
    let accountType: String?
    let label: String?

    var isCard: Bool { type == "card" }
    var isBank: Bool { type == "us_bank_account" }

    /// Display-safe description for a payment method row
    var displayName: String {
        if isCard {
            return "\((brand ?? "Card").capitalized) •••• \(last4 ?? "????")"
        } else if isBank {
            return "\(brand ?? "Bank") •••• \(last4 ?? "????")"
        } else {
            return label ?? type.capitalized
        }
    }
}

// MARK: GET /api/stripe/preview-fee?desired_net_cents=X&payment_method_type=Y
// Source: preview-fee/route.ts lines 26-31
// Public endpoint (no auth required).
struct FeePreviewResponse: Codable {
    let desiredNetCents: Int
    let chargeAmountCents: Int
    let feeCents: Int
    let paymentMethodType: String
}

// MARK: POST /api/stripe/create-payment-intent
// Source: create-payment-intent/route.ts lines 30-106
// Request body (snake_case): { desired_net_cents, payment_method_type, payment_method_id? }
// Response (camelCase): { clientSecret, paymentIntentId, chargeAmountCents, desiredNetCents, feeCents }
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

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let chargeAmountCents: Int
    let desiredNetCents: Int
    let feeCents: Int
}

// MARK: POST /api/stripe/cancel-payment-intent
// Source: cancel-payment-intent/route.ts lines 16-42
// Best-effort — swallows errors server-side.
struct CancelPaymentIntentBody: Encodable {
    let paymentIntentId: String
}

// MARK: POST /api/stripe/record-pending-payment
// Source: record-pending-payment/route.ts lines 18-43
// CRITICAL: backend REQUIRES both paymentIntentId AND amount (400 otherwise).
// `amount` is in DOLLARS (not cents) — matches parseFloat(payAmt) on web.
struct RecordPendingPaymentBody: Encodable {
    let paymentIntentId: String
    let amount: Double
}

// MARK: - Helpers

enum StripePaymentMethodType: String {
    case card
    case usBankAccount = "us_bank_account"
}

/// Converts a dollar amount to integer cents safely.
/// Backend rejects non-integer cents via Number.isInteger() check.
func dollarsToCents(_ dollars: Double) -> Int {
    Int(round(dollars * 100))
}

/// Converts integer cents back to dollars for record-pending-payment body.
func centsToDollars(_ cents: Int) -> Double {
    Double(cents) / 100.0
}
