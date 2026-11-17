import SwiftUI
import SwiftData

struct DashboardHeaderView: View {

    @Query private var profiles: [UserProfile]

    var onProfileTap: () -> Void

    // MARK: - User Name

    private var firstName: String {

        let fullName = profiles.first?.fullName
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !fullName.isEmpty else {
            return "There"
        }

        return String(
            fullName.split(whereSeparator: \.isWhitespace).first ?? "there"
        )
    }

    // MARK: - Profile Image

    private var profileImage: some View {

        Group {

            if let imageData = profiles.first?.profileImageData,
               let uiImage = UIImage(data: imageData) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()

            } else {

                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(4)

            }
        }
        .frame(width: 44, height: 44)
        .background(.white.opacity(0.18))
        .clipShape(Circle())
        .overlay {

            Circle()
                .stroke(.white.opacity(0.35), lineWidth: 1.5)

        }
    }

    // MARK: - Body

    var body: some View {

        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 5) {

                Text("Hey, \(firstName)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        AppColors.dashboardTextOnPurple
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Welcome back")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        AppColors.dashboardTextOnPurple.opacity(0.8)
                    )

            }

            Spacer(minLength: 8)

            
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Preview

#Preview {

    ZStack {

        AppColors.dashboardGradient
            .ignoresSafeArea()

        DashboardHeaderView(onProfileTap: {})
            .padding(.horizontal, 20)

    }
    .modelContainer(
        for: [
            Transaction.self,
            Budget.self,
            UserProfile.self
        ],
        inMemory: true
    )

}
