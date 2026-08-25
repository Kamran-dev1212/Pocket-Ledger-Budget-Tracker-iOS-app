import LocalAuthentication

/// Thin wrapper around LocalAuthentication's LAContext.
///
/// Uses `.deviceOwnerAuthentication`, which tries Face ID or Touch ID
/// first and automatically falls back to the device's own passcode if
/// biometrics fail or aren't set up. There is no separate in-app PIN
/// to build, store, or recover — the device's own passcode is the
/// fallback, exactly the same mechanism used to unlock the phone
/// itself.
enum AppLockManager {

    /// Returns true if the user successfully authenticated, or if the
    /// device has no passcode set at all — in that case there is
    /// nothing to check against, so the user is let through rather
    /// than locked out of the app permanently.
    static func authenticate() async -> Bool {

        let context = LAContext()

        var evaluationError: NSError?

        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &evaluationError
        )

        guard canEvaluate else {
            return true
        }

        do {

            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Pocket Ledger"
            )

        } catch {

            return false

        }

    }

}
