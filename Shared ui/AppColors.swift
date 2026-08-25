import SwiftUI

struct AppColors {

    // MARK: - Brand Colors

    static let primary = Color.adaptive(
        light: Color(red: 79/255, green: 70/255, blue: 229/255),   // Indigo
        dark: Color(red: 99/255, green: 102/255, blue: 241/255)    // Brighter for dark contrast
    )

    static let secondary = Color.adaptive(
        light: Color(red: 14/255, green: 165/255, blue: 233/255),  // Sky Blue
        dark: Color(red: 56/255, green: 189/255, blue: 248/255)
    )

    static let accent = Color.adaptive(
        light: Color(red: 167/255, green: 139/255, blue: 250/255), // Lavender
        dark: Color(red: 196/255, green: 181/255, blue: 253/255)
    )

    // MARK: - Semantic Colors

    static let success = Color.adaptive(
        light: Color(red: 16/255, green: 185/255, blue: 129/255),  // Emerald
        dark: Color(red: 52/255, green: 211/255, blue: 153/255)
    )

    static let expense = Color.adaptive(
        light: Color(red: 249/255, green: 115/255, blue: 22/255),  // Soft Orange
        dark: Color(red: 251/255, green: 146/255, blue: 60/255)
    )

    static let warning = Color.adaptive(
        light: Color(red: 245/255, green: 158/255, blue: 11/255),  // Amber
        dark: Color(red: 251/255, green: 191/255, blue: 36/255)
    )

    static let danger = Color.adaptive(
        light: Color(red: 239/255, green: 68/255, blue: 68/255),   // Red
        dark: Color(red: 248/255, green: 113/255, blue: 113/255)
    )

    // MARK: - Adaptive Neutrals (Light / Dark)

    static let background = Color.adaptive(
        light: Color(red: 246/255, green: 247/255, blue: 251/255),
        dark: Color(red: 18/255, green: 18/255, blue: 20/255)
    )

    static let card = Color.adaptive(
        light: Color.white,
        dark: Color(red: 28/255, green: 28/255, blue: 32/255)
    )

    // MARK: - Text

    static let textPrimary = Color.adaptive(
        light: Color(red: 30/255, green: 41/255, blue: 59/255),
        dark: Color(red: 245/255, green: 247/255, blue: 250/255)
    )

    static let textSecondary = Color.adaptive(
        light: Color(red: 100/255, green: 116/255, blue: 139/255),
        dark: Color(red: 148/255, green: 163/255, blue: 184/255)
    )

    // Text used on top of colored/gradient backgrounds (e.g. Balance Card)
    static let textOnPrimary = Color.white

    // MARK: - Divider / Border / Shadow

    static let divider = Color.adaptive(
        light: Color.gray.opacity(0.15),
        dark: Color.white.opacity(0.12)
    )

    static let border = Color.adaptive(
        light: Color.gray.opacity(0.12),
        dark: Color.white.opacity(0.12)
    )

    static let shadow = Color.adaptive(
        light: Color.black.opacity(0.06),
        dark: Color.black.opacity(0.4)
    )

    // MARK: - Shared Card System

    static let cardCornerRadius: CGFloat = 20
    static let heroCardCornerRadius: CGFloat = 32

    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 6

    static let heroShadowRadius: CGFloat = 20
    static let heroShadowY: CGFloat = 10

    // MARK: - Spacing System
    // 24pt between major sections, 16pt inside standard cards, 20pt page margins

    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let heroCardPadding: CGFloat = 28
    static let pageHorizontalPadding: CGFloat = 20

    // MARK: - Soft Tinted Card Backgrounds

    static let successBackground = success.opacity(0.08)
    static let expenseBackground = expense.opacity(0.08)
    static let incomeGradient: [Color] = [success, success.opacity(0.75)]
       static let expenseGradient: [Color] = [expense, expense.opacity(0.75)]


    // MARK: - Chart Palette

    static let chartPalette: [Color] = [
        primary,
        expense,
        success,
        secondary,
        accent,
        warning,
        danger,
        Color.teal,
        Color.pink
    ]

}

// MARK: - Adaptive Color Helper

extension Color {

    static func adaptive(light: Color, dark: Color) -> Color {

        Color(UIColor { traits in

            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)

        })

    }

}
