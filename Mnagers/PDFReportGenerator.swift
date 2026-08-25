import Foundation
import UIKit

enum PDFReportError: LocalizedError {

    case renderingFailed

    var errorDescription: String? {

        switch self {

        case .renderingFailed:
            return "Could not create the PDF statement. Please try again."

        }

    }

}

/// Builds a clean, printable PDF statement of all transactions and
/// budgets. This is a one-way, human-readable document — unlike the
/// JSON backup format it replaced, a PDF cannot be read back into the
/// app, since it has no way to import data.
enum PDFReportGenerator {

    // MARK: - Layout (A4)

    private static let pageWidth: CGFloat = 595.2
    private static let pageHeight: CGFloat = 841.8
    private static let margin: CGFloat = 40
    private static let contentWidth: CGFloat = pageWidth - margin * 2
    private static let bottomLimit: CGFloat = pageHeight - margin

    private static let incomeColor = UIColor(red: 0.13, green: 0.55, blue: 0.34, alpha: 1)
    private static let expenseColor = UIColor(red: 0.82, green: 0.33, blue: 0.15, alpha: 1)

    // MARK: - Generate

    static func createStatement(
        transactions: [Transaction],
        budgets: [Budget],
        currencyCode: String
    ) throws -> URL {

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let sortedTransactions = transactions.sorted { $0.date > $1.date }

        let sortedBudgets = budgets.sorted {
            ($0.year, $0.month, $0.category) > ($1.year, $1.month, $1.category)
        }

        let totalIncome = transactions
            .filter { $0.type == "Income" }
            .reduce(0) { $0 + $1.amount }

        let totalExpense = transactions
            .filter { $0.type == "Expense" }
            .reduce(0) { $0 + $1.amount }

        let rowDateFormatter = DateFormatter()
        rowDateFormatter.dateFormat = "d MMM yyyy"

        let generatedFormatter = DateFormatter()
        generatedFormatter.dateFormat = "d MMMM yyyy, h:mm a"

        let monthSymbols = Calendar.current.monthSymbols

        let data = renderer.pdfData { context in

            var cursorY: CGFloat = margin

            func startPage() {
                context.beginPage()
                cursorY = margin
            }

            func ensureSpace(_ height: CGFloat) {

                if cursorY + height > bottomLimit {
                    startPage()
                }

            }

            @discardableResult
            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor,
                x: CGFloat = margin,
                width: CGFloat = contentWidth
            ) -> CGFloat {

                let attributedString = NSAttributedString(
                    string: text,
                    attributes: [.font: font, .foregroundColor: color]
                )

                let boundingRect = attributedString.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    context: nil
                )

                let height = ceil(boundingRect.height)

                ensureSpace(height)

                attributedString.draw(
                    in: CGRect(x: x, y: cursorY, width: width, height: height)
                )

                cursorY += height

                return height

            }

            func drawRow(
                _ columns: [(text: String, width: CGFloat, color: UIColor)],
                font: UIFont
            ) {

                ensureSpace(16)

                var x = margin

                for column in columns {

                    NSAttributedString(
                        string: column.text,
                        attributes: [.font: font, .foregroundColor: column.color]
                    )
                    .draw(in: CGRect(x: x, y: cursorY, width: column.width, height: 16))

                    x += column.width

                }

                cursorY += 18

            }

            func drawDivider() {

                ensureSpace(10)

                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: cursorY + 4))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: cursorY + 4))

                UIColor.lightGray.withAlphaComponent(0.5).setStroke()
                path.lineWidth = 0.5
                path.stroke()

                cursorY += 12

            }

            startPage()

            // MARK: Header

            drawText("Pocket Ledger", font: .boldSystemFont(ofSize: 22), color: .black)
            drawText("Financial Statement", font: .systemFont(ofSize: 13), color: .darkGray)
            drawText(
                "Generated \(generatedFormatter.string(from: Date()))",
                font: .systemFont(ofSize: 10),
                color: .gray
            )

            cursorY += 12
            drawDivider()
            cursorY += 8

            // MARK: Summary

            drawText("Summary", font: .boldSystemFont(ofSize: 15), color: .black)
            cursorY += 4

            drawRow(
                [
                    (text: "Total Income", width: contentWidth / 2, color: .black),
                    (
                        text: CurrencyManager.string(for: totalIncome, currencyCode: currencyCode),
                        width: contentWidth / 2,
                        color: incomeColor
                    )
                ],
                font: .systemFont(ofSize: 12)
            )

            drawRow(
                [
                    (text: "Total Expenses", width: contentWidth / 2, color: .black),
                    (
                        text: CurrencyManager.string(for: totalExpense, currencyCode: currencyCode),
                        width: contentWidth / 2,
                        color: expenseColor
                    )
                ],
                font: .systemFont(ofSize: 12)
            )

            drawRow(
                [
                    (text: "Net Balance", width: contentWidth / 2, color: .black),
                    (
                        text: CurrencyManager.string(for: totalIncome - totalExpense, currencyCode: currencyCode),
                        width: contentWidth / 2,
                        color: .black
                    )
                ],
                font: .boldSystemFont(ofSize: 12)
            )

            cursorY += 4

            drawRow(
                [
                    (text: "Transactions", width: contentWidth / 2, color: .darkGray),
                    (text: "\(sortedTransactions.count)", width: contentWidth / 2, color: .darkGray)
                ],
                font: .systemFont(ofSize: 11)
            )

            drawRow(
                [
                    (text: "Budgets", width: contentWidth / 2, color: .darkGray),
                    (text: "\(sortedBudgets.count)", width: contentWidth / 2, color: .darkGray)
                ],
                font: .systemFont(ofSize: 11)
            )

            cursorY += 16
            drawDivider()
            cursorY += 8

            // MARK: Transactions

            drawText("Transactions", font: .boldSystemFont(ofSize: 15), color: .black)
            cursorY += 8

            if sortedTransactions.isEmpty {

                drawText(
                    "No transactions recorded yet.",
                    font: .italicSystemFont(ofSize: 11),
                    color: .gray
                )

            } else {

                let dateWidth = contentWidth * 0.20
                let categoryWidth = contentWidth * 0.22
                let titleWidth = contentWidth * 0.33
                let amountWidth = contentWidth * 0.25

                drawRow(
                    [
                        (text: "Date", width: dateWidth, color: .darkGray),
                        (text: "Category", width: categoryWidth, color: .darkGray),
                        (text: "Title", width: titleWidth, color: .darkGray),
                        (text: "Amount", width: amountWidth, color: .darkGray)
                    ],
                    font: .boldSystemFont(ofSize: 10)
                )

                drawDivider()

                for transaction in sortedTransactions {

                    let isIncome = transaction.type == "Income"

                    let amountText = CurrencyManager.string(
                        for: transaction.amount,
                        currencyCode: currencyCode,
                        forcedSign: isIncome ? "+" : "-"
                    )

                    drawRow(
                        [
                            (
                                text: rowDateFormatter.string(from: transaction.date),
                                width: dateWidth,
                                color: .black
                            ),
                            (text: transaction.category, width: categoryWidth, color: .black),
                            (text: transaction.title, width: titleWidth, color: .black),
                            (
                                text: amountText,
                                width: amountWidth,
                                color: isIncome ? incomeColor : expenseColor
                            )
                        ],
                        font: .systemFont(ofSize: 10)
                    )

                }

            }

            // MARK: Budgets

            cursorY += 16
            drawDivider()
            cursorY += 8

            drawText("Budgets", font: .boldSystemFont(ofSize: 15), color: .black)
            cursorY += 8

            if sortedBudgets.isEmpty {

                drawText(
                    "No budgets created yet.",
                    font: .italicSystemFont(ofSize: 11),
                    color: .gray
                )

            } else {

                let categoryWidth = contentWidth * 0.4
                let periodWidth = contentWidth * 0.3
                let amountWidth = contentWidth * 0.3

                drawRow(
                    [
                        (text: "Category", width: categoryWidth, color: .darkGray),
                        (text: "Period", width: periodWidth, color: .darkGray),
                        (text: "Amount", width: amountWidth, color: .darkGray)
                    ],
                    font: .boldSystemFont(ofSize: 10)
                )

                drawDivider()

                for budget in sortedBudgets {

                    let periodName: String = {

                        guard budget.month >= 1, budget.month <= monthSymbols.count else {
                            return String(budget.year)
                        }

                        return "\(monthSymbols[budget.month - 1]) \(budget.year)"

                    }()

                    drawRow(
                        [
                            (text: budget.category, width: categoryWidth, color: .black),
                            (text: periodName, width: periodWidth, color: .black),
                            (
                                text: CurrencyManager.string(for: budget.amount, currencyCode: currencyCode),
                                width: amountWidth,
                                color: .black
                            )
                        ],
                        font: .systemFont(ofSize: 10)
                    )

                }

            }

        }

        let filenameDateFormatter = DateFormatter()
        filenameDateFormatter.dateFormat = "yyyy-MM-dd"

        let filename = "Pocket Ledger Statement \(filenameDateFormatter.string(from: Date())).pdf"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {

            try data.write(to: url, options: .atomic)

        } catch {

            throw PDFReportError.renderingFailed

        }

        return url

    }

}
