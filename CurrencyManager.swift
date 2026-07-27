import Foundation

struct CurrencyManager {

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

}
