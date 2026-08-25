import SwiftUI
import SwiftData

struct DashboardHeaderView: View {

    @Query private var profiles: [UserProfile]

    var onProfileTap: () -> Void

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
                    .foregroundStyle(AppColors.primary)
                    .padding(4)

            }

        }
        .frame(width: 44, height: 44)
        .background(AppColors.primary.opacity(0.12))
        .clipShape(Circle())
        .overlay {

            Circle()
                .stroke(AppColors.primary.opacity(0.25), lineWidth: 1.5)

        }

    }

    // MARK: - Body

    var body: some View {

        Button {

            onProfileTap()

        } label: {

            profileImage

        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")

    }

}

#Preview {

    DashboardHeaderView(onProfileTap: {})
        .modelContainer(
            for: [
                Transaction.self,
                Budget.self,
                UserProfile.self
            ],
            inMemory: true
        )

}
