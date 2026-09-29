import Foundation

struct CurrencyManager {

    // MARK: - Symbols

    /// Every currency offered in Settings, in picker order.
    static let supportedCurrencies = [
        "USD", "EUR", "GBP", "CAD", "AUD", "NZD", "CHF",
        "SEK", "NOK", "DKK", "AED", "SAR", "QAR", "SGD",
        "INR", "PKR"
    ]

    static func symbol(for currencyCode: String) -> String {

        switch currencyCode {

        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        case "NZD": return "NZ$"
        case "SGD": return "S$"
        case "INR": return "₹"
        case "PKR": return "Rs. "
        default: return currencyCode + " "

        }

    }

    // MARK: - Shared Formatter

    private static let numberFormatter: NumberFormatter = {

        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.roundingMode = .halfUp
        formatter.locale = Locale.current

        return formatter

    }()

    // MARK: - Number Only (no symbol, no sign)

    static func number(for amount: Double) -> String {

        let value = rounded(abs(amount))

        let hasFraction = value.truncatingRemainder(dividingBy: 1) != 0

        numberFormatter.minimumFractionDigits = hasFraction ? 2 : 0
        numberFormatter.maximumFractionDigits = hasFraction ? 2 : 0

        return numberFormatter.string(from: NSNumber(value: value))
            ?? String(format: hasFraction ? "%.2f" : "%.0f", value)

    }

    // MARK: - Full Display String

    static func string(
        for amount: Double,
        currencyCode: String,
        forcedSign: String? = nil
    ) -> String {

        let sign = forcedSign ?? (rounded(amount) < 0 ? "-" : "")

        return sign
            + symbol(for: currencyCode)
            + number(for: amount)

    }

    static func signedString(
        for amount: Double,
        currencyCode: String
    ) -> String {

        string(
            for: amount,
            currencyCode: currencyCode,
            forcedSign: rounded(amount) < 0 ? "-" : "+"
        )

    }

    // MARK: - Rounding

    static func rounded(_ amount: Double) -> Double {

        (amount * 100).rounded() / 100

    }

    // MARK: - Parsing

    static func amount(from text: String) -> Double? {

        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "'", with: "")

        guard !cleaned.isEmpty else {
            return nil
        }

        let lastDot = cleaned.lastIndex(of: ".")
        let lastComma = cleaned.lastIndex(of: ",")

        switch (lastDot, lastComma) {

        case let (dot?, comma?):

            if dot > comma {

                cleaned = cleaned.replacingOccurrences(of: ",", with: "")

            } else {

                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")

            }

        case (nil, let comma?):

            // Commas followed by exactly three digits are thousands
            // separators ("1,234", "1,234,567"); otherwise it's a decimal
            // comma ("12,5").
            let digitsAfter = cleaned[cleaned.index(after: comma)...]
            let isThousands = digitsAfter.count == 3
                && digitsAfter.allSatisfy(\.isNumber)

            cleaned = cleaned.replacingOccurrences(
                of: ",",
                with: isThousands ? "" : "."
            )

        default:

            break

        }

        // Double() also accepts "inf" and "nan", and huge values would
        // trap later when converted for display.
        guard let value = Double(cleaned),
              value.isFinite,
              abs(value) < 1_000_000_000_000
        else {
            return nil
        }

        return rounded(value)

    }

    static func isValidAmount(_ text: String) -> Bool {

        guard let value = amount(from: text) else {
            return false
        }

        return value > 0

    }

    // MARK: - Editing

    static func editableText(for amount: Double) -> String {

        let value = rounded(amount)

        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.2f", value)

    }

}

// MARK: - Region-Based Default Currency
//
// Detects a sensible starting currency from the device's region,
// used only once — the very first time the app is ever launched on
// a device, before the user has chosen anything themselves. Once a
// currency has been explicitly set (by this or by the user), this
// code never runs again for that install.

extension CurrencyManager {

    /// The device region's currency when the app supports it, otherwise
    /// USD. Changing it later is still a Premium feature, but free users
    /// in the UK, EU, Gulf, etc. shouldn't be stuck on "$".
    static func detectDefaultCurrency() -> String {

        let code = Locale.current.currency?.identifier ?? "USD"

        return supportedCurrencies.contains(code) ? code : "USD"

    }

    /// Writes the detected currency into storage, but only if no
    /// currency has ever been set for this install. Safe to call on
    /// every app launch — after the first time, this is a no-op, so
    /// it can never overwrite a currency the user has since chosen.
    static func applyDetectedCurrencyIfNeeded() {

        let key = "selectedCurrency"

        guard UserDefaults.standard.string(forKey: key) == nil else {
            return
        }

        UserDefaults.standard.set(
            detectDefaultCurrency(),
            forKey: key
        )

    }

}
