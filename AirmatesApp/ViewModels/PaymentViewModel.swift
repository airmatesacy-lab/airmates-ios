import Foundation
import StripePaymentSheet

/// State machine for a single payment flow.
enum PaymentFlowState: Equatable {
    case idle
    case loadingMethods
    case creatingIntent
    case presentingSheet
    case processing   // ACH — webhook will confirm later
    case success
    case failed(String)
    case canceled

    var isWorking: Bool {
        switch self {
        case .loadingMethods, .creatingIntent, .presentingSheet: return true
        default: return false
        }
    }
}

/// Owns all state for the in-app payment flow. Pin to @MainActor because
/// Stripe's PaymentSheet completion closure fires on the main thread, and
/// we want state mutations from it to be synchronous without DispatchQueue
/// dances.
@MainActor
@Observable
final class PaymentViewModel {
    // MARK: - Inputs

    /// The member's current owed balance in dollars (positive number).
    let balanceDueDollars: Double

    /// The amount the user wants to pay, in dollars. Defaults to full balance.
    var amountDollars: Double

    /// "card" or "us_bank_account"
    var paymentMethodType: String = StripePaymentMethodType.card.rawValue

    // MARK: - Loaded state

    var savedMethods: [SavedPaymentMethod] = []
    var selectedMethodId: String?
    var feePreview: FeePreviewResponse?
    var stripeEnabled: Bool = true

    // MARK: - Flow state

    var flowState: PaymentFlowState = .idle
    var errorMessage: String?

    /// Set after createPaymentIntent() succeeds; cleared on completion/cancel.
    /// Used for cancelPaymentIntent cleanup on dismiss.
    private(set) var activePaymentIntentId: String?
    private(set) var activeClientSecret: String?

    /// Whether the user picked an ACH method (affects post-confirmation handling).
    var isAchSelected: Bool {
        paymentMethodType == StripePaymentMethodType.usBankAccount.rawValue
    }

    // MARK: - Debouncing for fee preview

    private var feePreviewTask: Task<Void, Never>?

    // MARK: - Init

    init(balanceDueDollars: Double) {
        self.balanceDueDollars = balanceDueDollars
        self.amountDollars = balanceDueDollars
    }

    // MARK: - Loaders

    func loadSavedMethods() async {
        flowState = .loadingMethods
        do {
            let resp = try await StripeService.shared.fetchPaymentMethods()
            self.savedMethods = resp.methods.filter { $0.supported ?? true }
            self.stripeEnabled = resp.stripeEnabled
            if let defaultId = resp.defaultPaymentMethodId,
               self.savedMethods.contains(where: { $0.id == defaultId }) {
                self.selectedMethodId = defaultId
                // Sync payment method type to default
                if let defaultMethod = self.savedMethods.first(where: { $0.id == defaultId }) {
                    self.paymentMethodType = defaultMethod.type
                }
            }
            flowState = .idle
            // Kick off initial fee preview
            schedulePreviewUpdate()
        } catch {
            flowState = .idle
            self.errorMessage = friendlyError(from: error)
        }
    }

    /// Debounced fee preview refresh. Call whenever amount or method type changes.
    func schedulePreviewUpdate() {
        feePreviewTask?.cancel()
        feePreviewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms debounce
            guard !Task.isCancelled, let self else { return }
            await self.fetchFeePreview()
        }
    }

    private func fetchFeePreview() async {
        let cents = dollarsToCents(amountDollars)
        guard cents > 0 else {
            feePreview = nil
            return
        }
        do {
            let preview = try await StripeService.shared.previewFee(
                desiredNetCents: cents,
                type: paymentMethodType
            )
            // Only update if the amount/type still match (user may have typed more)
            if preview.desiredNetCents == cents, preview.paymentMethodType == paymentMethodType {
                self.feePreview = preview
            }
        } catch {
            // Non-fatal — pre-sheet still works without fee preview
            self.feePreview = nil
        }
    }

    // MARK: - Payment

    /// Creates a PaymentIntent on the backend. On success, caller should
    /// construct a PaymentSheet with activeClientSecret and present it.
    func createPaymentIntent() async -> Bool {
        guard dollarsToCents(amountDollars) > 0 else {
            errorMessage = "Amount must be greater than $0."
            return false
        }
        flowState = .creatingIntent
        errorMessage = nil
        do {
            let resp = try await StripeService.shared.createPaymentIntent(
                desiredNetCents: dollarsToCents(amountDollars),
                type: paymentMethodType,
                paymentMethodId: selectedMethodId
            )
            self.activeClientSecret = resp.clientSecret
            self.activePaymentIntentId = resp.paymentIntentId
            flowState = .presentingSheet
            return true
        } catch {
            flowState = .failed(friendlyError(from: error))
            self.errorMessage = friendlyError(from: error)
            return false
        }
    }

    /// Handle the completion result from Stripe's PaymentSheet.
    func handlePaymentResult(_ result: PaymentSheetResult) async {
        switch result {
        case .completed:
            // For ACH, the payment is still processing — record it as pending
            // so the user's ledger shows "Processing" until the webhook fires.
            if isAchSelected, let piId = activePaymentIntentId {
                do {
                    try await StripeService.shared.recordPendingPayment(
                        paymentIntentId: piId,
                        desiredNetCents: dollarsToCents(amountDollars)
                    )
                    flowState = .processing
                } catch {
                    // Failed to record pending — not fatal, webhook will still
                    // reconcile when funds settle. Show success anyway.
                    flowState = .processing
                }
            } else {
                flowState = .success
            }
            clearActivePI()

        case .canceled:
            flowState = .canceled
            await cancelActivePaymentIntent()

        case .failed(let error):
            flowState = .failed(friendlyError(from: error))
            errorMessage = friendlyError(from: error)
            // Don't cancel — user may retry with a different card
        }
    }

    /// Cancel the in-flight PaymentIntent (best-effort).
    /// Called from PayBalanceSheet on swipe-dismiss, scene-background, etc.
    func cancelActivePaymentIntent() async {
        guard let piId = activePaymentIntentId else { return }
        await StripeService.shared.cancelPaymentIntent(paymentIntentId: piId)
        clearActivePI()
    }

    private func clearActivePI() {
        activePaymentIntentId = nil
        activeClientSecret = nil
    }

    // MARK: - Error mapping

    /// Maps raw errors to pilot-friendly messages. Stripe SDK errors are often
    /// already reasonable ("Your card was declined"), but backend 500s and
    /// resource_missing codes leak through raw — catch the common ones.
    private func friendlyError(from error: Error) -> String {
        let raw = error.localizedDescription.lowercased()

        if raw.contains("network") || raw.contains("offline") || raw.contains("internet") {
            return "No internet connection. Check your signal and try again."
        }
        if raw.contains("insufficient_funds") || raw.contains("insufficient funds") {
            return "Insufficient funds. Please try a different payment method."
        }
        if raw.contains("card_declined") || raw.contains("was declined") {
            return "Your card was declined. Please try a different payment method."
        }
        if raw.contains("resource_missing") || raw.contains("no such customer") {
            return "Payment method no longer valid. Please add a new card."
        }
        if raw.contains("expired_card") {
            return "Your card has expired. Please use a different card."
        }
        if raw.contains("incorrect_cvc") {
            return "Incorrect security code. Please check your card details."
        }
        if raw.contains("processing_error") {
            return "Stripe is having trouble processing your card. Please try again."
        }
        if raw.contains("not yet enabled") {
            return "Online payments aren't enabled for your club. Please contact your treasurer."
        }
        // Default — don't leak raw jargon
        return "Payment failed. Please try again or contact your treasurer."
    }
}
