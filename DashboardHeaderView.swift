import SwiftUI
import SwiftData

struct DashboardHeaderView: View {

    // MARK: - Profile

    @Query private var profiles: [UserProfile]

    // MARK: - Greeting

    private var greeting: String {

        let hour = Calendar.current.component(
            .hour,
            from: Date()
        )

        switch hour {

        case 5..<12:
            return "Good Morning ☀️"

        case 12..<17:
            return "Good Afternoon 🌤️"

        default:
            return "Good Evening 🌙"

        }

    }

    // MARK: - User Name

    private var userName: String {

        guard let profile = profiles.first else {
            return ""
        }

        return profile.fullName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

    }

    // MARK: - Profile Image

    private var profileImage: some View {

        Group {

            if let imageData = profiles.first?.profileImageData,
               let uiImage = UIImage(
                    data: imageData
               ) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()

            } else {

                Image(
                    systemName:
                        "person.crop.circle.fill"
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    AppColors.primary
                )
                .padding(4)

            }

        }
        .frame(
            width: 52,
            height: 52
        )
        .background(
            AppColors.primary.opacity(0.12)
        )
        .clipShape(
            Circle()
        )
        .overlay {

            Circle()
                .stroke(
                    AppColors.primary.opacity(0.25),
                    lineWidth: 1.5
                )

        }

    }

    // MARK: - Body

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 12
        ) {

            // MARK: - Tappable Profile Picture

            if let profile = profiles.first {

                NavigationLink {

                    EditProfileView(
                        profile: profile
                    )

                } label: {

                    profileImage

                }
                .buttonStyle(
                    .plain
                )

            } else {

                profileImage

            }

            // MARK: - Greeting Content

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(greeting)
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                    .lineLimit(1)

                Text(
                    userName.isEmpty
                    ? "Welcome back 👋"
                    : "Welcome back, \(userName) 👋"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            }

            Spacer()

        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )

    }

}

#Preview {

    DashboardHeaderView()
        .modelContainer(
            for: [
                Transaction.self,
                Budget.self,
                UserProfile.self
            ],
            inMemory: true
        )

}
