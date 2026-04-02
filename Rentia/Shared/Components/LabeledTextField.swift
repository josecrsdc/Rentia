import SwiftUI

/// A form row that always shows a label above the TextField,
/// so the label remains visible when the field has a value.
/// Designed for use inside SwiftUI `Form` / `Section` rows.
struct LabeledTextField: View {
    let label: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal
    var multilineLimit: ClosedRange<Int>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            textField
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var textField: some View {
        let field = TextField(placeholder, text: $text, axis: axis)
            .font(AppTypography.body)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .keyboardType(keyboardType)
        if let range = multilineLimit {
            field.lineLimit(range)
        } else {
            field
        }
    }
}
