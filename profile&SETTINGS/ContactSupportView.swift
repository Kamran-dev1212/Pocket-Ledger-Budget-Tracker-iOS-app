import SwiftUI
import MessageUI

struct ContactSupportView: View {

    // MARK: - State

    @State private var showingMailComposer = false
    @State private var showingMailUnavailableAlert = false

    // MARK: - Support Email

    private let supportEmail = "kamranzaidi79@gmail.com"

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: - Header

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Image(
                            systemName: "envelope.badge.fill"
                        )
                        .font(.system(size: 44))
                        .foregroundStyle(
                            AppColors.primary
                        )

                        Text("We're Here to Help")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text(
                            "Have a question, found a problem, or have a suggestion? We would love to hear from you."
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            AppColors.textSecondary
                        )
                        .lineSpacing(4)

                    }

                    // MARK: - Contact Button

                    Button {

                        if MFMailComposeViewController
                            .canSendMail() {

                            showingMailComposer = true

                        } else {

                            showingMailUnavailableAlert = true

                        }

                    } label: {

                        HStack(spacing: 14) {

                            Image(
                                systemName: "envelope.fill"
                            )
                            .font(.title3)

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("Email Support")
                                    .font(.headline)

                                Text(supportEmail)
                                    .font(.subheadline)
                                    .opacity(0.85)

                            }

                            Spacer()

                            Image(
                                systemName: "chevron.right"
                            )
                            .font(.caption)
                            .fontWeight(.bold)

                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(
                            maxWidth: .infinity
                        )
                        .background(
                            AppColors.primary,
                            in: RoundedRectangle(
                                cornerRadius: 16
                            )
                        )

                    }
                    .buttonStyle(.plain)

                    // MARK: - Support Information

                    supportSection(
                        title: "Before Contacting Support",
                        icon: "lightbulb.fill"
                    ) {

                        Text(
                            """
                            When contacting support, please include as much information as possible about your question or problem.

                            Helpful information may include:

                            • What you were trying to do
                            • What happened
                            • The steps that caused the problem
                            • Your iPhone model
                            • Your iOS version
                            """
                        )

                    }

                    // MARK: - Feature Requests

                    supportSection(
                        title: "Feature Suggestions",
                        icon: "sparkles"
                    ) {

                        Text(
                            """
                            Have an idea that could make Pocket Ledger better?

                            Send us your suggestions. User feedback helps us improve the app and decide which features to build next.
                            """
                        )

                    }

                    // MARK: - Footer

                    VStack(spacing: 6) {

                        Text("Pocket Ledger: Budget Tracker")
                            .font(.headline)
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text(
                            "We appreciate your feedback."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.top, 12)

                }
                .padding()

            }

        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Mail Composer

        .sheet(
            isPresented: $showingMailComposer
        ) {

            MailView(
                recipients: [supportEmail],
                subject: "Pocket Ledger Support"
            )

        }

        // MARK: - Mail Unavailable Alert

        .alert(
            "Email Not Available",
            isPresented: $showingMailUnavailableAlert
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(
                "Please configure an email account in the Mail app on your device before contacting support."
            )

        }

    }

    // MARK: - Support Section

    private func supportSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(spacing: 10) {

                Image(systemName: icon)
                    .foregroundStyle(
                        AppColors.primary
                    )

                Text(title)
                    .font(.headline)
                    .foregroundStyle(
                        AppColors.textPrimary
                    )

            }

            content()
                .font(.subheadline)
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .lineSpacing(4)

        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            AppColors.card
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            x: 0,
            y: 2
        )

    }

}

// MARK: - Mail View

struct MailView: UIViewControllerRepresentable {

    let recipients: [String]
    let subject: String

    @Environment(\.dismiss)
    private var dismiss

    func makeUIViewController(
        context: Context
    ) -> MFMailComposeViewController {

        let composer =
            MFMailComposeViewController()

        composer.setToRecipients(
            recipients
        )

        composer.setSubject(
            subject
        )

        composer.mailComposeDelegate =
            context.coordinator

        return composer

    }

    func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: Context
    ) { }

    func makeCoordinator()
        -> Coordinator {

        Coordinator(
            dismiss: dismiss
        )

    }

    final class Coordinator:
        NSObject,
        MFMailComposeViewControllerDelegate {

        let dismiss: DismissAction

        init(
            dismiss: DismissAction
        ) {

            self.dismiss = dismiss

        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {

            dismiss()

        }

    }

}

// MARK: - Preview

#Preview {

    NavigationStack {

        ContactSupportView()

    }

}
