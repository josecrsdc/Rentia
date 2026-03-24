import SwiftUI

struct NotificationSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("settings.preferences.notifications")
                .sectionTitle()

            OverduePaymentsBlock()

            LeaseExpiryBlock()
        }
        .cardStyle()
    }
}

private struct OverduePaymentsBlock: View {
    @AppStorage("notifyOverduePayments")
    private var notifyOverduePayments = true
    @AppStorage("notifyOverdueHour")
    private var notifyOverdueHour: Int = 9
    @AppStorage("notifyOverdueMinute")
    private var notifyOverdueMinute: Int = 0

    private var overdueTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: notifyOverdueHour,
                    minute: notifyOverdueMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                notifyOverdueHour = comps.hour ?? 9
                notifyOverdueMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                SettingsSectionIcon(systemName: "bell.badge")

                Text("settings.preferences.notifications.overdue_payments")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Toggle("", isOn: $notifyOverduePayments)
                    .labelsHidden()
                    .tint(AppTheme.Colors.primary)
            }

            Text("settings.preferences.notifications.overdue_payments.description")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 44)

            if notifyOverduePayments {
                HStack(spacing: AppSpacing.medium) {
                    SettingsSectionIcon(systemName: "clock")

                    Text("settings.preferences.notifications.time")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Spacer()

                    DatePicker("", selection: overdueTimeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(AppTheme.Colors.primary)
                }
                .padding(.top, AppSpacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.Colors.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .onChange(of: notifyOverduePayments) {
            if !notifyOverduePayments {
                Task {
                    await NotificationService.shared.scheduleOverduePaymentsNotification(overdueCount: 0)
                }
            }
        }
    }
}

private struct LeaseExpiryBlock: View {
    @AppStorage("notifyLeaseExpiry")
    private var notifyLeaseExpiry = true
    @AppStorage("notifyLeaseHour")
    private var notifyLeaseHour: Int = 9
    @AppStorage("notifyLeaseMinute")
    private var notifyLeaseMinute: Int = 0
    @AppStorage("notifyLeaseWarning1")
    private var notifyLeaseWarning1: Int = 60
    @AppStorage("notifyLeaseWarning2")
    private var notifyLeaseWarning2: Int = 30

    private let warningDaysOptions = [7, 14, 30, 45, 60, 90]

    private var leaseTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: notifyLeaseHour,
                    minute: notifyLeaseMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                notifyLeaseHour = comps.hour ?? 9
                notifyLeaseMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                SettingsSectionIcon(systemName: "calendar.badge.clock")

                Text("settings.preferences.notifications.lease_expiry")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Toggle("", isOn: $notifyLeaseExpiry)
                    .labelsHidden()
                    .tint(AppTheme.Colors.primary)
            }

            Text("settings.preferences.notifications.lease_expiry.description")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 44)

            if notifyLeaseExpiry {
                VStack(spacing: AppSpacing.medium) {
                    HStack(spacing: AppSpacing.medium) {
                        SettingsSectionIcon(systemName: "clock")

                        Text("settings.preferences.notifications.time")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

                        DatePicker("", selection: leaseTimeBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(AppTheme.Colors.primary)
                    }

                    HStack(spacing: AppSpacing.medium) {
                        SettingsSectionIcon(systemName: "1.circle")

                        Text("settings.preferences.notifications.first_warning")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

                        Picker("", selection: $notifyLeaseWarning1) {
                            ForEach(warningDaysOptions, id: \.self) { days in
                                Text(
                                    String(
                                        format: String(
                                            localized: "settings.preferences.notifications.days_before"
                                        ),
                                        days
                                    )
                                ).tag(days)
                            }
                        }
                        .tint(AppTheme.Colors.primary)
                    }

                    HStack(spacing: AppSpacing.medium) {
                        SettingsSectionIcon(systemName: "2.circle")

                        Text("settings.preferences.notifications.second_warning")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

                        Picker("", selection: $notifyLeaseWarning2) {
                            ForEach(warningDaysOptions, id: \.self) { days in
                                Text(
                                    String(
                                        format: String(
                                            localized: "settings.preferences.notifications.days_before"
                                        ),
                                        days
                                    )
                                ).tag(days)
                            }
                        }
                        .tint(AppTheme.Colors.primary)
                    }
                }
                .padding(.top, AppSpacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.Colors.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .onChange(of: notifyLeaseExpiry) {
            if !notifyLeaseExpiry {
                Task {
                    await NotificationService.shared.scheduleLeaseExpiryNotifications(leases: [])
                }
            }
        }
    }
}
