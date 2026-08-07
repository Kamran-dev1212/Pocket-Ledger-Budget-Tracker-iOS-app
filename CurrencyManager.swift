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

    /// Formats the magnitude of a value.
    /// Whole values drop the decimals ("2,500"),
    /// fractional values keep two ("2,500.75").
    static func number(for amount: Double) -> String {

        let value = rounded(abs(amount))

        let hasFraction = value.truncatingRemainder(dividingBy: 1) != 0

        numberFormatter.minimumFractionDigits = hasFraction ? 2 : 0
        numberFormatter.maximumFractionDigits = hasFraction ? 2 : 0

        return numberFormatter.string(from: NSNumber(value: value))
            ?? String(format: hasFraction ? "%.2f" : "%.0f", value)

    }

    // MARK: - Full Display String

    /// Symbol + amount. A negative value renders its minus sign
    /// ahead of the symbol ("-Rs. 500").
    ///
    /// Pass `forcedSign` when the stored value is positive but the
    /// row needs an explicit direction, e.g. an income row that
    /// should read "+Rs. 500".
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

    /// Always shows a direction. Used for net totals
    /// ("+Rs. 1,200" / "-Rs. 300").
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

    /// Money is stored to two decimal places. Everything that writes
    /// to a model should pass through here so 0.1 + 0.2 style drift
    /// never reaches the database.
    static func rounded(_ amount: Double) -> Double {

        (amount * 100).rounded() / 100

    }

    // MARK: - Parsing

    /// Converts text from an amount field into a value.
    ///
    /// `Double("12,50")` returns nil, which silently disables the Save
    /// button for anyone in a comma-decimal locale. This accepts either
    /// separator, and strips spaces and grouping marks.
    ///
    /// Input arrives from a `.decimalPad`, so at most one separator is
    /// typed in practice. When both appear, the last one is treated as
    /// the decimal separator and the rest as grouping.
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

            // Both present — whichever comes last is the decimal mark.

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

    /// A value is usable as a transaction or budget amount when it
    /// parses and is greater than zero.
    static func isValidAmount(_ text: String) -> Bool {

        guard let value = amount(from: text) else {
            return false
        }

        return value > 0

    }

    // MARK: - Editing

    /// Turns a stored value back into editable text, preserving
    /// decimals. Replaces the `String(Int(amount))` calls that were
    /// truncating on edit.
    static func editableText(for amount: Double) -> String {

        let value = rounded(amount)

        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.2f", value)

    }

}
