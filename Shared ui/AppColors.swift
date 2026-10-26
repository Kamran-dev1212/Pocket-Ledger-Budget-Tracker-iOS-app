import SwiftUI

struct AppColors {

    // MARK: - Pocket Ledger Dashboard Theme

    // Vibrant purple gradient colors
    static let dashboardPurple = Color(
        red: 119.0 / 255.0,
        green: 62.0 / 255.0,
        blue: 245.0 / 255.0
    )

    static let dashboardPurpleLight = Color(
        red: 147.0 / 255.0,
        green: 79.0 / 255.0,
        blue: 255.0 / 255.0
    )

    static let dashboardPurpleDark = Color(
        red: 81.0 / 255.0,
        green: 38.0 / 255.0,
        blue: 199.0 / 255.0
    )

    // Main dashboard header gradient
    static let dashboardGradient = LinearGradient(
        colors: [
            dashboardPurpleLight,
            dashboardPurple,
            dashboardPurpleDark
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Dashboard content surface
    // White in Light Mode, dark surface in Dark Mode
    static let dashboardSurface = Color.adaptive(
        light: .white,
        dark: Color(
            red: 28.0 / 255.0,
            green: 28.0 / 255.0,
            blue: 32.0 / 255.0
        )
    )

    // Dashboard quick-access button background
    static let dashboardShortcutBackground = Color.adaptive(
        light: Color(
            red: 245.0 / 255.0,
            green: 241.0 / 255.0,
            blue: 255.0 / 255.0
        ),
        dark: Color(
            red: 48.0 / 255.0,
            green: 37.0 / 255.0,
            blue: 72.0 / 255.0
        )
    )

    // Dashboard-specific text and icon colors
    static let dashboardTextOnPurple = Color.white

    static let dashboardShortcutIcon = dashboardPurple

    // Dashboard layout
    static let dashboardContentCornerRadius: CGFloat = 32

    static let dashboardShortcutCornerRadius: CGFloat = 18

    static let dashboardFloatingButtonSize: CGFloat = 64

    // MARK: - Brand Colors

    static let primary = Color.adaptive(
        light: Color(
            red: 79.0 / 255.0,
            green: 70.0 / 255.0,
            blue: 229.0 / 255.0
        ),
        dark: Color(
            red: 99.0 / 255.0,
            green: 102.0 / 255.0,
            blue: 241.0 / 255.0
        )
    )

    static let secondary = Color.adaptive(
        light: Color(
            red: 14.0 / 255.0,
            green: 165.0 / 255.0,
            blue: 233.0 / 255.0
        ),
        dark: Color(
            red: 56.0 / 255.0,
            green: 189.0 / 255.0,
            blue: 248.0 / 255.0
        )
    )

    static let accent = Color.adaptive(
        light: Color(
            red: 167.0 / 255.0,
            green: 139.0 / 255.0,
            blue: 250.0 / 255.0
        ),
        dark: Color(
            red: 196.0 / 255.0,
            green: 181.0 / 255.0,
            blue: 253.0 / 255.0
        )
    )

    // MARK: - Semantic Colors

    static let success = Color.adaptive(
        light: Color(
            red: 16.0 / 255.0,
            green: 185.0 / 255.0,
            blue: 129.0 / 255.0
        ),
        dark: Color(
            red: 52.0 / 255.0,
            green: 211.0 / 255.0,
            blue: 153.0 / 255.0
        )
    )

    static let expense = Color.adaptive(
        light: Color(
            red: 249.0 / 255.0,
            green: 115.0 / 255.0,
            blue: 22.0 / 255.0
        ),
        dark: Color(
            red: 251.0 / 255.0,
            green: 146.0 / 255.0,
            blue: 60.0 / 255.0
        )
    )

    static let warning = Color.adaptive(
        light: Color(
            red: 245.0 / 255.0,
            green: 158.0 / 255.0,
            blue: 11.0 / 255.0
        ),
        dark: Color(
            red: 251.0 / 255.0,
            green: 191.0 / 255.0,
            blue: 36.0 / 255.0
        )
    )

    static let danger = Color.adaptive(
        light: Color(
            red: 239.0 / 255.0,
            green: 68.0 / 255.0,
            blue: 68.0 / 255.0
        ),
        dark: Color(
            red: 248.0 / 255.0,
            green: 113.0 / 255.0,
            blue: 113.0 / 255.0
        )
    )

    // MARK: - Adaptive Neutrals

    static let background = Color.adaptive(
        light: Color(
            red: 246.0 / 255.0,
            green: 247.0 / 255.0,
            blue: 251.0 / 255.0
        ),
        dark: Color(
            red: 18.0 / 255.0,
            green: 18.0 / 255.0,
            blue: 20.0 / 255.0
        )
    )

    static let card = Color.adaptive(
        light: .white,
        dark: Color(
            red: 28.0 / 255.0,
            green: 28.0 / 255.0,
            blue: 32.0 / 255.0
        )
    )

    // MARK: - Text Colors

    static let textPrimary = Color.adaptive(
        light: Color(
            red: 30.0 / 255.0,
            green: 41.0 / 255.0,
            blue: 59.0 / 255.0
        ),
        dark: Color(
            red: 245.0 / 255.0,
            green: 247.0 / 255.0,
            blue: 250.0 / 255.0
        )
    )

    static let textSecondary = Color.adaptive(
        light: Color(
            red: 100.0 / 255.0,
            green: 116.0 / 255.0,
            blue: 139.0 / 255.0
        ),
        dark: Color(
            red: 148.0 / 255.0,
            green: 163.0 / 255.0,
            blue: 184.0 / 255.0
        )
    )

    // Text displayed on colored backgrounds
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

    static let sectionSpacing: CGFloat = 24

    static let cardPadding: CGFloat = 16

    static let heroCardPadding: CGFloat = 28

    static let pageHorizontalPadding: CGFloat = 20

    // MARK: - Soft Tinted Card Backgrounds

    static let successBackground = success.opacity(0.08)

    static let expenseBackground = expense.opacity(0.08)

    static let incomeGradient: [Color] = [
        success,
        success.opacity(0.75)
    ]

    static let expenseGradient: [Color] = [
        expense,
        expense.opacity(0.75)
    ]

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

    static func adaptive(
        light: Color,
        dark: Color
    ) -> Color {

        Color(
            UIColor { traits in

                traits.userInterfaceStyle == .dark
                    ? UIColor(dark)
                    : UIColor(light)

            }
        )

    }

}
