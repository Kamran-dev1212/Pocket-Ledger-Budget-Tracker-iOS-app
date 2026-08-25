import SwiftUI

struct SettingsRowView: View {

    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var showChevron: Bool = true
    var isDisabled: Bool = false

    var body: some View {

        HStack(spacing: 14) {

            ZStack {

                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)

            }

            VStack(alignment: .leading, spacing: 2) {

                Text(title)
                    .font(.body)
                    .foregroundStyle(
                        isDisabled ? AppColors.textSecondary : AppColors.textPrimary
                    )

                if let subtitle {

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                }

            }

            Spacer()

            if let trailingText {

                Text(trailingText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

            }

            if showChevron {

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))

            }

        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: 0) {

            SettingsRowView(
                icon: "square.and.arrow.up.fill",
                iconColor: AppColors.primary,
                title: "Export Data"
            )

            Divider()
                .background(AppColors.divider)

            SettingsRowView(
                icon: "faceid",
                iconColor: AppColors.textSecondary,
                title: "Face ID",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

        }
        .padding()
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()

    }

}
