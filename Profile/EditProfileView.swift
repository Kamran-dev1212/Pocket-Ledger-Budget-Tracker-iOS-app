import SwiftUI
import SwiftData
import PhotosUI

struct EditProfileView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Profile

    let profile: UserProfile

    // MARK: - Temporary Editing State

    @State private var fullName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var occupation: String
    @State private var bio: String

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var temporaryImageData: Data?

    // MARK: - UI State

    @State private var showDiscardAlert = false
    @State private var showSaveError = false
    @State private var showPhotoError = false

    // MARK: - Keyboard Focus

    @FocusState private var focusedField: Field?

    private enum Field {
        case fullName
        case email
        case phoneNumber
        case occupation
        case bio
    }

    // MARK: - Initializer

    init(profile: UserProfile) {

        self.profile = profile

        _fullName = State(
            initialValue: profile.fullName
        )

        _email = State(
            initialValue: profile.email
        )

        _phoneNumber = State(
            initialValue: profile.phoneNumber
        )

        _occupation = State(
            initialValue: profile.occupation
        )

        _bio = State(
            initialValue: profile.bio
        )

        _temporaryImageData = State(
            initialValue: profile.profileImageData
        )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Profile Photo

                profilePhotoSection

                // MARK: - Personal Information

                profileSection(
                    title: "Personal Information"
                ) {

                    VStack(spacing: 16) {

                        profileTextField(
                            title: "Full Name",
                            text: $fullName,
                            placeholder: "Enter your full name",
                            keyboardType: .default,
                            field: .fullName
                        )

                        profileTextField(
                            title: "Email",
                            text: $email,
                            placeholder: "Enter your email address",
                            keyboardType: .emailAddress,
                            field: .email
                        )

                        profileTextField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "Enter your phone number",
                            keyboardType: .phonePad,
                            field: .phoneNumber
                        )

                        profileTextField(
                            title: "Occupation",
                            text: $occupation,
                            placeholder: "Enter your occupation",
                            keyboardType: .default,
                            field: .occupation
                        )
                    }
                }

                // MARK: - About

                profileSection(
                    title: "About"
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Bio")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                AppColors.primary
                            )

                        TextEditor(text: $bio)
                            .focused(
                                $focusedField,
                                equals: .bio
                            )
                            .frame(minHeight: 120)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(
                                AppColors.background
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                            .overlay {

                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                                .stroke(
                                    AppColors.divider,
                                    lineWidth: 1
                                )
                            }
                    }
                }

                // MARK: - Save Button

                Button {

                    saveProfile()

                } label: {

                    Text("Save Changes")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            16
                        )
                        .background(
                            AppColors.primary,
                            in: RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(
                    fullName
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                )
                .opacity(
                    fullName
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                    ? 0.5
                    : 1
                )
            }
            .padding()
        }
        .background(
            AppColors.background
        )
        .navigationTitle(
            "Edit Profile"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )

        // MARK: - Hide Automatic Back Button

        .navigationBarBackButtonHidden(
            true
        )

        // MARK: - Toolbar

        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button("Cancel") {

                    showDiscardAlert = true
                }
            }
        }

        // MARK: - Discard Alert

        .alert(
            "Discard Changes?",
            isPresented: $showDiscardAlert
        ) {

            Button(
                "Keep Editing",
                role: .cancel
            ) { }

            Button(
                "Discard",
                role: .destructive
            ) {

                dismiss()
            }

        } message: {

            Text(
                "Your unsaved profile changes will be lost."
            )
        }

        // MARK: - Save Error Alert

        .alert(
            "Unable to Save",
            isPresented: $showSaveError
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(
                "Please enter your full name before saving."
            )
        }

        // MARK: - Photo Error Alert

        .alert(
            "Unable to Load Photo",
            isPresented: $showPhotoError
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(
                "The selected photo could not be loaded. Please try another photo."
            )
        }

        }

    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {

        VStack(spacing: 12) {

            profileImageView

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {

                Label(
                    "Change Photo",
                    systemImage: "camera.fill"
                )
                .font(
                    .subheadline
                )
                .fontWeight(
                    .semibold
                )
                .foregroundStyle(
                    AppColors.primary
                )
            }
            .onChange(
                of: selectedPhoto
            ) { _, newItem in

                Task {

                    guard let newItem else {
                        return
                    }

                    do {

                        if let data = try await newItem
                            .loadTransferable(
                                type: Data.self
                            ),
                           let image = UIImage(
                                data: data
                           ),
                           let jpegData = image.jpegData(
                                compressionQuality: 0.85
                           ) {

                            await MainActor.run {

                                temporaryImageData = jpegData
                            }

                        } else {

                            await MainActor.run {

                                showPhotoError = true
                            }
                        }

                    } catch {

                        await MainActor.run {

                            showPhotoError = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Image

    private var profileImageView: some View {

        Group {

            if let temporaryImageData,
               let uiImage = UIImage(
                    data: temporaryImageData
               ) {

                Image(
                    uiImage: uiImage
                )
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
                .padding(10)
            }
        }
        .frame(
            width: 120,
            height: 120
        )
        .background(
            AppColors.primary.opacity(
                0.12
            )
        )
        .clipShape(
            Circle()
        )
        .overlay {

            Circle()
                .stroke(
                    AppColors.primary.opacity(
                        0.25
                    ),
                    lineWidth: 2
                )
        }
    }

    // MARK: - Text Field

    private func profileTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType,
        field: Field
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(
                    .subheadline
                )
                .fontWeight(
                    .medium
                )
                .foregroundStyle(
                    AppColors.primary
                )

            TextField(
                placeholder,
                text: text
            )
            .focused(
                $focusedField,
                equals: field
            )
            .keyboardType(
                keyboardType
            )
            .textInputAutocapitalization(
                keyboardType == .emailAddress
                ? .never
                : .sentences
            )
            .autocorrectionDisabled(
                keyboardType == .emailAddress
            )
            .submitLabel(
                field == .bio
                ? .done
                : .next
            )
            .onSubmit {

                moveToNextField(
                    from: field
                )
            }
            .padding(
                .horizontal,
                14
            )
            .padding(
                .vertical,
                13
            )
            .background(
                AppColors.background
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 12
                )
                .stroke(
                    AppColors.divider,
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Move Between Fields

    private func moveToNextField(
        from field: Field
    ) {

        switch field {

        case .fullName:

            focusedField = .email

        case .email:

            focusedField = .phoneNumber

        case .phoneNumber:

            focusedField = .occupation

        case .occupation:

            focusedField = .bio

        case .bio:

            focusedField = nil
        }
    }

    // MARK: - Section Container

    private func profileSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(title)
                .font(
                    .headline
                )
                .foregroundStyle(
                    AppColors.textPrimary
                )

            content()
        }
        .padding()
        .background(
            AppColors.card
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: AppColors.shadow,
            radius: 8,
            x: 0,
            y: 3
        )
    }

    // MARK: - Save Profile

    private func saveProfile() {

        let cleanedName = fullName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedName.isEmpty else {

            showSaveError = true

            return
        }

        profile.fullName = cleanedName

        profile.email = email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        profile.phoneNumber = phoneNumber
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        profile.occupation = occupation
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        profile.bio = bio
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        profile.profileImageData = temporaryImageData

        dismiss()
    }
}

#Preview {
    Text("EditProfileView Preview")
}
