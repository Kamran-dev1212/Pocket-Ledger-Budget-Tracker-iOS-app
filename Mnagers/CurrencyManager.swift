import Foundation

struct CurrencyManager {

    // MARK: - Symbols

    static func symbol(for currencyCode: String) -> String {

        switch currencyCode {

        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "AED": return "AED "
        case "INR": return "₹"
        default: return "Rs. "

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

        case (nil, .some):

            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")

        default:

            break

        }

        guard let value = Double(cleaned) else {
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

    /// Maps the device's region to one of the currencies this app
    /// already knows how to symbolize and format. Every Gulf country
    /// maps to AED for now rather than adding a currency per country.
    /// Anything not recognized falls back to USD.
    static func detectDefaultCurrency() -> String {

        guard let regionCode = Locale.current.region?.identifier else {
            return "USD"
        }

        let gulfRegions: Set<String> = [
            "AE", "SA", "QA", "KW", "BH", "OM"
        ]

        let eurozoneRegions: Set<String> = [
            "AT", "BE", "CY", "EE", "FI", "FR", "DE", "GR", "IE",
            "IT", "LV", "LT", "LU", "MT", "NL", "PT", "SK", "SI", "ES",
            "HR", "AD", "MC", "SM", "VA"
        ]

        switch regionCode {

        case "PK":
            return "PKR"

        case "US":
            return "USD"

        case "GB":
            return "GBP"

        case "IN":
            return "INR"

        case _ where gulfRegions.contains(regionCode):
            return "AED"

        case _ where eurozoneRegions.contains(regionCode):
            return "EUR"

        default:
            return "USD"

        }

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
