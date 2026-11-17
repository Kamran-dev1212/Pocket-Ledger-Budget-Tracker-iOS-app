import SwiftUI

struct DashboardShortcutView: View {
    let title: String
    let icon: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.dashboardPurple)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                AppColors.dashboardPurple.opacity(0.10),
                in: RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
    }
}
