import XCTest
@testable import SwiftMath

/// End-to-end smoke test: a formula containing CJK text must render to a
/// non-empty image without error (glyphs are supplied by the CoreText font
/// cascade since the bundled math fonts contain no CJK glyphs).
final class CJKRenderSmokeTests: XCTestCase {
    func testRenderCJKFormula() throws {
        var mi = MathImage(
            latex: #"\frac{管彎曲角度 \times 2 \times \pi \times 彎曲半徑}{360°} \times 1.05"#,
            fontSize: 34, textColor: MTColor.black, labelMode: .display, textAlignment: .left)
        let (error, image, layout) = mi.asImage()
        XCTAssertNil(error)
        let img = try XCTUnwrap(image)
        XCTAssertNotNil(layout)
        XCTAssertGreaterThan(img.size.width, 100)
        XCTAssertGreaterThan(img.size.height, 20)
    }
}
