import Foundation
import StripePaymentSheet

/// Centralized wrapper for all Stripe-related API calls and SDK configuration.
/// Follows the singleton pattern used by APIClient / AuthService / KeychainManager.
///
/// This service does NOT make direct calls to Stripe's API — it only calls the
/// Airmates backend, which handles the actual Stripe Connect / PaymentIntent
/// creation with transfer_data routing funds to each club's connected account.
final class StripeService {
    static let shared = StripeService()

    private var isConfigured = false

    private init() {}

    // MARK: - SDK Configuration

    /// Sets the Stripe publishable key. Call once at app launch from AirmatesApp.task.
    /// Idempotent — safe to call multiple times.
    func configure() {
        guard !isConfigured else { return }
        StripeAPI.defaultPublishableKey = AppConstants.stripePublishableKey
        isConfigured = true
    }

    // MARK: - API Calls

    /// GET /api/stripe/payment-methods
    /// Lists the user's saved payment methods from Stripe.
    func fetchPaymentMethods() async throws -> PaymentMethodsResponse {
        try await APIClient.shared.getWithRetry("/api/stripe/payment-methods")
    }

    /// GET /api/stripe/preview-fee
    /// Calculates the inflated charge amount to cover Stripe's processing fee.
    /// Public endpoint (no auth required), but we use the authenticated client
    /// anyway for consistency.
    func previewFee(desiredNetCents: Int, type: String) async throws -> FeePreviewResponse {
        try await APIClient.shared.getWithRetry(
            "/api/stripe/preview-fee",
            query: [
                URLQueryItem(name: "desired_net_cents", value: String(desiredNetCents)),
                URLQueryItem(name: "payment_method_type", value: type),
            ]
        )
    }

    /// POST /api/stripe/create-payment-intent
    /// Creates a PaymentIntent with the inflated amount. The response clientSecret
    /// is what PaymentSheet consumes for the actual payment flow.
    func createPaymentIntent(
        desiredNetCents: Int,
        type: String,
        paymentMethodId: String? = nil
    ) async throws -> PaymentIntentResponse {
        let body = CreatePaymentIntentBody(
            desiredNetCents: desiredNetCents,
            paymentMethodType: type,
            paymentMethodId: paymentMethodId
        )
        return try await APIClient.shared.postWithRetry("/api/stripe/create-payment-intent", body: body)
    }

    /// POST /api/stripe/cancel-payment-intent
    /// Cancels an abandoned PaymentIntent. Best-effort — errors are swallowed
    /// server-side and here. Mirror of the web's AppShell.tsx:1721 behavior.
    /// Call from:
    ///   - PayBalanceSheet on swipe-to-dismiss (if a PI was created but not confirmed)
    ///   - PaymentSheet .canceled result
    ///   - Scene going to background with an open PI
    func cancelPaymentIntent(paymentIntentId: String) async {
        do {
            let body = CancelPaymentIntentBody(paymentIntentId: paymentIntentId)
            let _: EmptyResponse = try await APIClient.shared.postWithRetry(
                "/api/stripe/cancel-payment-intent",
                body: body
            )
        } catch {
            // Best-effort cleanup — log and continue
            print("[StripeService] cancelPaymentIntent failed: \(error.localizedDescription)")
        }
    }

    /// POST /api/stripe/record-pending-payment
    /// Records an ACH payment as PENDING immediately (before the webhook fires)
    /// so the user's ledger shows "Processing" in real time.
    /// The backend requires BOTH paymentIntentId AND amount (in dollars).
    func recordPendingPayment(paymentIntentId: String, desiredNetCents: Int) async throws {
        let body = RecordPendingPaymentBody(
            paymentIntentId: paymentIntentId,
            amount: centsToDollars(desiredNetCents)
        )
        let _: EmptyResponse = try await APIClient.shared.postWithRetry(
            "/api/stripe/record-pending-payment",
            body: body
        )
    }
}

/// Used for endpoints that return `{ok: true}` or similar, where we only care
/// about HTTP status, not the body shape.
private struct EmptyResponse: Decodable {}
