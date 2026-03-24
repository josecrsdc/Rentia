import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.titleKey, systemImage: tab.icon, value: tab) {
                    navigationContent(for: tab)
                }
            }
        }
        .tint(AppTheme.Colors.primary)
    }

    @ViewBuilder
    private func navigationContent(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            NavigationStack {
                DashboardView()
            }
        case .properties:
            PropertyListView()
        case .tenants:
            TenantListView()
        case .payments:
            PaymentListView()
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}
