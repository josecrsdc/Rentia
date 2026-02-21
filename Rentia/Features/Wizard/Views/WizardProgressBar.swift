import SwiftUI

struct WizardProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let labels: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { index in
                stepCircle(index: index)

                if index < totalSteps - 1 {
                    stepLine(after: index)
                }
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
    }

    private func stepCircle(index: Int) -> some View {
        VStack(spacing: AppSpacing.extraSmall) {
            ZStack {
                Circle()
                    .fill(circleColor(for: index))
                    .frame(width: 32, height: 32)

                if index < currentStep {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(index == currentStep ? .white : AppTheme.Colors.textSecondary)
                }
            }

            Text(labels.indices.contains(index) ? labels[index] : "")
                .font(AppTypography.caption2)
                .foregroundStyle(
                    index <= currentStep
                        ? AppTheme.Colors.textPrimary
                        : AppTheme.Colors.textSecondary
                )
                .lineLimit(1)
                .fixedSize()
        }
    }

    private func stepLine(after index: Int) -> some View {
        Rectangle()
            .fill(
                index < currentStep
                    ? AppTheme.Colors.primary
                    : AppTheme.Colors.textLight
            )
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
    }

    private func circleColor(for index: Int) -> Color {
        if index < currentStep {
            return AppTheme.Colors.primary
        }
        if index == currentStep {
            return AppTheme.Colors.primary
        }
        return AppTheme.Colors.textLight
    }
}
