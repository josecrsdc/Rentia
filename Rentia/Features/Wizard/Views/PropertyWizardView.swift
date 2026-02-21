import SwiftUI

struct PropertyWizardView: View {
    @State private var viewModel = PropertyWizardViewModel()
    @State private var showCancelConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WizardProgressBar(
                    currentStep: viewModel.stepIndex,
                    totalSteps: viewModel.totalSteps,
                    labels: viewModel.stepLabels
                )

                Divider()

                stepContent
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("wizard.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        if viewModel.stepIndex > 0 {
                            showCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("wizard.cancel_confirm.title",
                isPresented: $showCancelConfirmation
            ) {
                Button("wizard.cancel_confirm.exit", role: .destructive) {
                    dismiss()
                }
                Button("wizard.cancel_confirm.continue", role: .cancel) {}
            } message: {
                Text("wizard.cancel_confirm.message")
            }
        }
        .onChange(of: viewModel.isCompleted) {
            if viewModel.isCompleted {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .property:
            PropertyFormView(
                propertyId: nil,
                onSaved: { savedId in
                    viewModel.advanceFromProperty(savedId: savedId)
                }
            )

        case .tenant:
            TenantFormView(
                tenantId: nil,
                preAssignedPropertyIds: [viewModel.createdPropertyId].compactMap { $0 },
                onSaved: { savedId in
                    viewModel.advanceFromTenant(savedId: savedId)
                }
            )

        case .lease:
            LeaseFormView(
                leaseId: nil,
                propertyId: viewModel.createdPropertyId,
                tenantId: viewModel.createdTenantId,
                prefilledRent: viewModel.createdPropertyRent,
                onSaved: { savedId in
                    viewModel.advanceFromLease(savedId: savedId)
                }
            )

        case .generatePayments:
            WizardPaymentGenerationView(wizardViewModel: viewModel)
        }
    }
}
