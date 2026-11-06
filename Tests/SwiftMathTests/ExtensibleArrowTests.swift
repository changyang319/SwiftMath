import XCTest
@testable import SwiftMath

/// `\xrightarrow[below]{above}` / `\xleftarrow[below]{above}` support.
final class ExtensibleArrowTests: XCTestCase {

    private func parse(_ latex: String) throws -> MTMathList {
        var error: NSError? = nil
        let list = MTMathListBuilder.build(fromString: latex, error: &error)
        XCTAssertNil(error, error?.localizedDescription ?? "")
        return try XCTUnwrap(list)
    }

    func testParseRightArrowWithLabel() throws {
        let list = try parse(#"A\xrightarrow{\text{H}_2\text{SO}_4}B"#)
        XCTAssertEqual(list.atoms.count, 3)
        let arrow = try XCTUnwrap(list.atoms[1] as? MTExtensibleArrow)
        XCTAssertFalse(arrow.leftward)
        XCTAssertEqual(arrow.type, .largeOperator)
        XCTAssertNotNil(arrow.upperLabel)
        XCTAssertNil(arrow.lowerLabel)
        XCTAssertNil(arrow.superScript)
        XCTAssertNil(arrow.subScript)
    }

    func testParseLeftArrowWithBothLabels() throws {
        let list = try parse(#"\xleftarrow[below]{above}"#)
        let arrow = try XCTUnwrap(list.atoms.first as? MTExtensibleArrow)
        XCTAssertTrue(arrow.leftward)
        XCTAssertEqual(arrow.upperLabel?.atoms.count, 5)
        XCTAssertEqual(arrow.lowerLabel?.atoms.count, 5)
    }

    func testRoundTripToString() throws {
        XCTAssertEqual(MTMathListBuilder.mathListToString(try parse(#"\xrightarrow{x}"#)), #"\xrightarrow{x}"#)
        XCTAssertEqual(MTMathListBuilder.mathListToString(try parse(#"\xleftarrow[y]{x}"#)), #"\xleftarrow[y]{x}"#)
    }

    func testCopyAndFinalizeKeepArrow() throws {
        let list = try parse(#"\xrightarrow[b]{a}"#)
        let finalized = try XCTUnwrap(list.finalized.atoms.first as? MTExtensibleArrow)
        XCTAssertEqual(finalized.upperLabel?.atoms.count, 1)
        XCTAssertEqual(finalized.lowerLabel?.atoms.count, 1)
    }

    func testArrowStretchesToLabelAndIsSpacedAsRelation() throws {
        let font = MTFontManager.fontManager.defaultFont
        let short = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse(#"\xrightarrow{a}"#), font: font, style: .text))
        let long = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse(#"\xrightarrow{\text{H}_2\text{SO}_4\text{ catalyst}}"#), font: font, style: .text))
        XCTAssertGreaterThan(long.width, short.width)

        // The label must fit within the arrow and sit above the baseline.
        let arrowDisplay = try XCTUnwrap(long.subDisplays.first as? MTLargeOpLimitsDisplay)
        let label = try XCTUnwrap(arrowDisplay.upperLimit)
        XCTAssertLessThan(label.width, arrowDisplay.width)
        XCTAssertGreaterThan(label.position.y, 0)

        // Relation spacing: a\xrightarrow{x}b is wider than the bare parts by the thick spaces.
        let spaced = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse(#"a\xrightarrow{x}b"#), font: font, style: .text))
        let a = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse("a"), font: font, style: .text))
        let b = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse("b"), font: font, style: .text))
        let arrowOnly = try XCTUnwrap(MTTypesetter.createLineForMathList(try parse(#"\xrightarrow{x}"#), font: font, style: .text))
        XCTAssertGreaterThan(spaced.width, a.width + b.width + arrowOnly.width + 1)
    }

    /// The two chemistry formulas from the 化學 question bank that motivated this feature.
    func testRenderChemistryFormulas() throws {
        let formulas = [
            #"\text{C}_6\text{H}_6+\text{HNO}_3\xrightarrow{\text{H}_2\text{SO}_4}\text{C}_6\text{H}_5\text{NO}_2+\text{H}_2\text{O}"#,
            #"\text{CH}_3\text{-CH=CH}_2+\text{HBr}\xrightarrow{\text{H}_2\text{O}_2}"#,
        ]
        for latex in formulas {
            for mode in [MTMathUILabelMode.text, .display] {
                var mi = MathImage(latex: latex, fontSize: 30, textColor: MTColor.black, labelMode: mode, textAlignment: .left)
                let (error, image, _) = mi.asImage()
                XCTAssertNil(error, "\(latex): \(error?.localizedDescription ?? "")")
                let img = try XCTUnwrap(image)
                XCTAssertGreaterThan(img.size.width, 100)
            }
        }
    }
}
