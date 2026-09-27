import Testing
import Foundation
import PDFKit
@testable import PDFKitExt

private final class FixtureLocator {}


private func data(_ name: String) throws -> Data {
    let bundle = Bundle(for: FixtureLocator.self)
    let url = try #require(bundle.url(forResource: name, withExtension: "pdf", subdirectory: "test-pdfs"),
                           "missing fixture \(name).pdf")
    return try Data(contentsOf: url)
}


struct PDFKitExtTests {
    @Test func example() async throws {
        let document = try #require(PDFDocument(data: data("multi_font_mixed")))
        let fonts = document.fonts
        for (i, font) in fonts.enumerated() {
            print("font[\(i)]: \(font)")
        }
    }
}
