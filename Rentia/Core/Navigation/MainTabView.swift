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
            NavigationStack {
                PropertyListView()
            }
        case .tenants:
            NavigationStack {
                TenantListView()
            }
        case .payments:
            NavigationStack {
                PaymentListView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}
