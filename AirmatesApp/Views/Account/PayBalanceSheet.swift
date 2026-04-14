import SwiftUI
import StripePaymentSheet

/// In-app payment flow. Custom pre-sheet (amount + fee preview + saved
/// methods) then presents Stripe's PaymentSheet for the actual card/ACH
/// input and confirmation.
struct PayBalanceSheet: View {
    let balanceDueDollars: Double
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var viewModel: PaymentViewModel
    @State private var paymentSheet: PaymentSheet?
    @State private var showPaymentSheet: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showProcessing: Bool = false

    init(balanceDueDollars: Double, onComplete: @escaping () -> Void) {
        self.balanceDueDollars = balanceDueDollars
        self.onComplete = onComplete
        _viewModel = State(initialValue: PaymentViewModel(balanceDueDollars: balanceDueDollars))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    balanceHeader
                    amountInput
                    paymentTypePicker
                    feeBreakdown
                    savedMethodsSection
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Pay Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { handleCancel() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                payButton
                    .padding()
                    .background(.regularMaterial)
            }
        }
        .task {
            await viewModel.loadSavedMethods()
        }
        .paymentSheet(
            isPresented: $showPaymentSheet,
            paymentSheet: paymentSheet ?? emptyPaymentSheet()
        ) { result in
            Task { @MainActor in
                await viewModel.handlePaymentResult(result)
                switch viewModel.flowState {
                case .success:
                    showSuccess = true
                case .processing:
                    showProcessing = true
                case .failed, .canceled, .idle, .loadingMethods, .creatingIntent, .presentingSheet:
                    break
                }
            }
        }
        .alert("Payment Successful", isPresented: $showSuccess) {
            Button("Done") {
                onComplete()
                dismiss()
            }
        } message: {
            Text("Your payment has been processed. Thanks!")
        }
        .alert("Payment Processing", isPresented: $showProcessing) {
            Button("Done") {
                onComplete()
                dismiss()
            }
        } message: {
            Text("Your bank transfer has been submitted. It will take 1-3 business days to clear. The charge will appear on your account as \"Processing\" until it settles.")
        }
        .onChange(of: viewModel.amountDollars) { _, _ in
            viewModel.schedulePreviewUpdate()
        }
        .onChange(of: viewModel.paymentMethodType) { _, _ in
            viewModel.schedulePreviewUpdate()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Amount Due")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "$%.2f", balanceDueDollars))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.brandRed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var amountInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Payment Amount")
                .font(.subheadline.bold())
            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.secondary)
                TextField("0.00", value: $viewModel.amountDollars, format: .number.precision(.fractionLength(2)))
                    .font(.title2)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            if viewModel.amountDollars > balanceDueDollars {
                Text("This is more than your balance — the extra will become a credit.")
                    .font(.caption)
                    .foregroundColor(.brandOrange)
            }
        }
    }

    @ViewBuilder
    private var paymentTypePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Payment Method")
                .font(.subheadline.bold())
            Picker("Payment Method", selection: $viewModel.paymentMethodType) {
                Text("Card").tag(StripePaymentMethodType.card.rawValue)
                Text("Bank Account").tag(StripePaymentMethodType.usBankAccount.rawValue)
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var feeBreakdown: some View {
        if let preview = viewModel.feePreview, preview.feeCents > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fee Breakdown")
                    .font(.subheadline.bold())
                VStack(spacing: 6) {
                    feeRow("Amount to club", cents: preview.desiredNetCents, color: .primary)
                    feeRow("Processing fee", cents: preview.feeCents, color: .secondary)
                    Divider()
                    feeRow("Total charge", cents: preview.chargeAmountCents, color: .brandBlue, bold: true)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func feeRow(_ label: String, cents: Int, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(String(format: "$%.2f", Double(cents) / 100.0))
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundColor(color)
        }
    }

    @ViewBuilder
    private var savedMethodsSection: some View {
        if !viewModel.savedMethods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Saved Payment Methods")
                    .font(.subheadline.bold())
                ForEach(viewModel.savedMethods) { method in
                    SavedPaymentMethodRow(
                        method: method,
                        isSelected: viewModel.selectedMethodId == method.id
                    ) {
                        if viewModel.selectedMethodId == method.id {
                            viewModel.selectedMethodId = nil
                        } else {
                            viewModel.selectedMethodId = method.id
                            viewModel.paymentMethodType = method.type
                        }
                    }
                }
                Text("Or tap 'Pay' below to enter a new card or bank account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func errorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.brandRed)
            Text(error)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color.brandRed.opacity(0.08))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var payButton: some View {
        Button(action: { Task { await handlePayTap() } }) {
            HStack {
                if viewModel.flowState.isWorking {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 4)
                }
                if let preview = viewModel.feePreview {
                    Text(String(format: "Pay $%.2f", Double(preview.chargeAmountCents) / 100.0))
                        .font(.headline.bold())
                } else {
                    Text(String(format: "Pay $%.2f", viewModel.amountDollars))
                        .font(.headline.bold())
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.brandBlue)
            .cornerRadius(12)
        }
        .disabled(viewModel.flowState.isWorking || viewModel.amountDollars <= 0 || !viewModel.stripeEnabled)
    }

    // MARK: - Actions

    private func handlePayTap() async {
        let ok = await viewModel.createPaymentIntent()
        guard ok, let clientSecret = viewModel.activeClientSecret else { return }

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Airmates"
        config.allowsDelayedPaymentMethods = true
        config.returnURL = AppConstants.stripeReturnURL
        config.defaultBillingDetails.email = appState.currentUser?.email
        config.defaultBillingDetails.name = appState.currentUser?.name

        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor(Color.brandBlue)
        appearance.cornerRadius = 12
        config.appearance = appearance

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )
        showPaymentSheet = true
    }

    private func handleCancel() {
        Task { @MainActor in
            // Cancel any in-flight PI before dismissing
            await viewModel.cancelActivePaymentIntent()
            dismiss()
        }
    }

    /// Placeholder PaymentSheet used as a sentinel when the real one hasn't
    /// been constructed yet. The `.paymentSheet` modifier requires a
    /// non-optional value even when isPresented=false.
    private func emptyPaymentSheet() -> PaymentSheet {
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Airmates"
        return PaymentSheet(
            paymentIntentClientSecret: "pi_placeholder_secret_placeholder",
            configuration: config
        )
    }
}
