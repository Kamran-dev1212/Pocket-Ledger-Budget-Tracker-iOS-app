//
//  MyMoney_TrackerTests.swift
//  MyMoney TrackerTests
//
//  Created by macuser on 7/8/26.
//

import XCTest
import CloudKit
@testable import Pocket_Ledger

final class SettlementCalculatorTests: XCTestCase {

    private let alice = GroupParticipant(id: "alice", displayName: "Alice", alternateIDs: [], isCurrentUser: true)
    private let bob = GroupParticipant(id: "bob", displayName: "Bob", alternateIDs: ["bob@example.com"], isCurrentUser: false)
    private let cara = GroupParticipant(id: "cara", displayName: "Cara", alternateIDs: [], isCurrentUser: false)

    private func expense(
        _ amount: Double,
        paidBy: String,
        splitAmong: [String],
        isSettlement: Bool = false
    ) -> SharedExpense {

        let record = CKRecord(recordType: "SharedExpense")

        record["title"] = "Test"
        record["amount"] = amount
        record["paidByUserRecordID"] = paidBy
        record["paidByDisplayName"] = paidBy
        record["splitAmongUserRecordIDs"] = splitAmong
        record["date"] = Date()
        record["isSettlement"] = Int64(isSettlement ? 1 : 0)

        return SharedExpense(record: record)!

    }

    private func net(_ balances: [Balance], _ id: String) -> Double? {
        balances.first { $0.participantID == id }?.netAmount
    }

    func testEvenSplitBalances() {

        let balances = SettlementCalculator.balances(
            for: [expense(90, paidBy: "alice", splitAmong: ["alice", "bob", "cara"])],
            participants: [alice, bob, cara]
        )

        XCTAssertEqual(net(balances, "alice"), 60)
        XCTAssertEqual(net(balances, "bob"), -30)
        XCTAssertEqual(net(balances, "cara"), -30)

    }

    func testUnevenSplitStillNetsToZero() {

        let balances = SettlementCalculator.balances(
            for: [expense(10, paidBy: "alice", splitAmong: ["alice", "bob", "cara"])],
            participants: [alice, bob, cara]
        )

        let total = balances.reduce(0) { $0 + $1.netAmount }

        XCTAssertEqual(total, 0, accuracy: 0.001)
        XCTAssertEqual(net(balances, "alice"), 6.66)

    }

    func testAliasResolvesToSameParticipant() {

        let balances = SettlementCalculator.balances(
            for: [expense(40, paidBy: "alice", splitAmong: ["bob@example.com", "bob"])],
            participants: [alice, bob]
        )

        // The alias and the primary id are one person, so Bob owes it all once.
        XCTAssertEqual(net(balances, "bob"), -40)
        XCTAssertEqual(balances.count, 2)

    }

    func testFormerMemberKeepsBalance() {

        let balances = SettlementCalculator.balances(
            for: [expense(50, paidBy: "dan", splitAmong: ["alice", "dan"])],
            participants: [alice]
        )

        XCTAssertEqual(net(balances, "dan"), 25)
        XCTAssertEqual(net(balances, "alice"), -25)

    }

    func testSettlementCancelsDebt() {

        let balances = SettlementCalculator.balances(
            for: [
                expense(30, paidBy: "alice", splitAmong: ["bob"]),
                expense(30, paidBy: "bob", splitAmong: ["alice"], isSettlement: true)
            ],
            participants: [alice, bob]
        )

        XCTAssertEqual(net(balances, "alice"), 0)
        XCTAssertEqual(net(balances, "bob"), 0)
        XCTAssertTrue(SettlementCalculator.settlementPlan(from: balances).isEmpty)

    }

    func testSettlementPlanPaysEveryoneBack() {

        let balances = SettlementCalculator.balances(
            for: [
                expense(90, paidBy: "alice", splitAmong: ["alice", "bob", "cara"]),
                expense(30, paidBy: "bob", splitAmong: ["alice", "bob", "cara"])
            ],
            participants: [alice, bob, cara]
        )

        let plan = SettlementCalculator.settlementPlan(from: balances)

        var remaining = Dictionary(uniqueKeysWithValues: balances.map { ($0.participantID, $0.netAmount) })

        for payment in plan {
            XCTAssertGreaterThan(payment.amount, 0)
            remaining[payment.fromID, default: 0] += payment.amount
            remaining[payment.toID, default: 0] -= payment.amount
        }

        for (_, value) in remaining {
            XCTAssertEqual(value, 0, accuracy: 0.001)
        }

    }

}

final class CurrencyManagerTests: XCTestCase {

    func testRounding() {
        XCTAssertEqual(CurrencyManager.rounded(1.005 + 0.0001), 1.01)
        XCTAssertEqual(CurrencyManager.rounded(2.344), 2.34)
    }

    func testParsingHandlesCommonFormats() {
        XCTAssertEqual(CurrencyManager.amount(from: "1,234.50"), 1234.5)
        XCTAssertEqual(CurrencyManager.amount(from: "1.234,50"), 1234.5)
        XCTAssertEqual(CurrencyManager.amount(from: "12,5"), 12.5)
        XCTAssertEqual(CurrencyManager.amount(from: " 99 "), 99)
        XCTAssertNil(CurrencyManager.amount(from: ""))
        XCTAssertNil(CurrencyManager.amount(from: "abc"))
        XCTAssertEqual(CurrencyManager.amount(from: "1,234"), 1234)
        XCTAssertEqual(CurrencyManager.amount(from: "1,234,567"), 1234567)
        XCTAssertNil(CurrencyManager.amount(from: "inf"))
        XCTAssertNil(CurrencyManager.amount(from: "99999999999999999999"))
    }

    func testValidAmountRejectsZeroAndNegative() {
        XCTAssertFalse(CurrencyManager.isValidAmount("0"))
        XCTAssertFalse(CurrencyManager.isValidAmount("-5"))
        XCTAssertTrue(CurrencyManager.isValidAmount("0.01"))
    }

    func testEditableText() {
        XCTAssertEqual(CurrencyManager.editableText(for: 12), "12")
        XCTAssertEqual(CurrencyManager.editableText(for: 12.5), "12.50")
    }

    func testEverySupportedCurrencyHasItsOwnSymbol() {
        for code in CurrencyManager.supportedCurrencies where code != "PKR" {
            XCTAssertNotEqual(CurrencyManager.symbol(for: code), "Rs. ", code)
        }
    }

}
