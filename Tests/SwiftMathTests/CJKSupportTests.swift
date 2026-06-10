import XCTest
@testable import SwiftMath

/// Tests for CJK (and related fullwidth/symbol) character support in
/// `MTMathAtomFactory.atom(forCharacter:)`. Previously every character
/// outside ASCII 0x21–0x7E (except Cyrillic and accented Latin) was
/// silently dropped by the builder.
final class CJKSupportTests: XCTestCase {

    private func nuclei(_ list: MTMathList?) -> String {
        guard let list else { return "" }
        return list.atoms.map { $0.nucleus }.joined()
    }

    func testFractionWithChineseNumerator() throws {
        let str = "\\frac{管彎曲角度 \\times 2 \\times \\pi \\times 彎曲半徑}{360°}"
        var error: NSError?
        let list = MTMathListBuilder.build(fromString: str, error: &error)
        XCTAssertNil(error)
        let frac = try XCTUnwrap(list?.atoms.first as? MTFraction)
        let numerator = nuclei(frac.numerator)
        XCTAssertTrue(numerator.contains("管彎曲角度"), "numerator was: \(numerator)")
        XCTAssertTrue(numerator.contains("彎曲半徑"), "numerator was: \(numerator)")
        XCTAssertTrue(nuclei(frac.denominator).contains("360°"))
    }

    func testTextCommandWithFullwidthAndUnits() throws {
        let str = "\\text{k}_1\\text{＝0.4kcal/m}^2\\text{ h℃}"
        var error: NSError?
        let list = MTMathListBuilder.build(fromString: str, error: &error)
        XCTAssertNil(error)
        let all = nuclei(list)
        XCTAssertTrue(all.contains("＝"), "atoms were: \(all)")
        XCTAssertTrue(all.contains("℃"), "atoms were: \(all)")
    }

    func testFullwidthParentheses() throws {
        let str = "（全形括號）"
        var error: NSError?
        let list = MTMathListBuilder.build(fromString: str, error: &error)
        XCTAssertNil(error)
        XCTAssertEqual(nuclei(list), "（全形括號）")
    }

    func testCJKAtomTypes() throws {
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "管")?.type, .ordinary)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "、")?.type, .ordinary)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "㎝")?.type, .ordinary)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "＝")?.type, .relation)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "×")?.type, .binaryOperator)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "→")?.type, .relation)
        XCTAssertEqual(MTMathAtomFactory.atom(forCharacter: "θ")?.type, .variable)
    }

    func testHighFrequencyExamBankCharacters() throws {
        // Characters that appear frequently inside $$...$$ blocks in the
        // Techcerti exam bank and must not be dropped.
        let chars = "，、＝×÷±°℃℉→≒≡≦≧≠≈∞∠′‧…㎝㎏㎜㎎（）？％﹐﹥–—"
        for ch in chars {
            XCTAssertNotNil(MTMathAtomFactory.atom(forCharacter: ch),
                            "atom(forCharacter:) returned nil for '\(ch)' U+\(String(ch.utf32Char, radix: 16, uppercase: true))")
        }
    }

    func testCyrillicRegression() throws {
        let str = "Привет"
        var error: NSError?
        let list = MTMathListBuilder.build(fromString: str, error: &error)
        XCTAssertNil(error)
        XCTAssertEqual(nuclei(list), "Привет")
        XCTAssertEqual(list?.atoms.first?.type, .ordinary)
    }

    func testAsciiRegression() throws {
        // Plain ASCII math must be unaffected by the new cases.
        let str = "\\frac{a+b}{2} = c^2"
        var error: NSError?
        let list = MTMathListBuilder.build(fromString: str, error: &error)
        XCTAssertNil(error)
        XCTAssertEqual(list?.atoms.first?.type, .fraction)
    }

    func testUnsupportedCharactersStillDropped() throws {
        XCTAssertNil(MTMathAtomFactory.atom(forCharacter: "\u{200B}")) // zero-width space
        XCTAssertNil(MTMathAtomFactory.atom(forCharacter: "😀"))
    }
}
