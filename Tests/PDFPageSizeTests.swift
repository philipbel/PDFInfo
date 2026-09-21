import Testing
import Foundation
@testable import PDF_Info

@Suite("PDFPageSize equality")
struct PDFPageSizeTests {
    @Test("Same physical size compares equal across units")
    func crossUnitEquality() {
        let inches = PDFPageSize(width: .init(value: 8.5, unit: .inches),
                                  height: .init(value: 11, unit: .inches))
        let millimeters = PDFPageSize(width: .init(value: 215.9, unit: .millimeters),
                                       height: .init(value: 279.4, unit: .millimeters))
        #expect(inches == millimeters)
    }

    @Test("Differences beyond epsilon are not equal")
    func beyondEpsilonDiffers() {
        let letter = PDFPageSize.letter
        let taller = PDFPageSize(width: .init(value: 8.5, unit: .inches),
                                  height: .init(value: 11.1, unit: .inches))
        #expect(letter != taller)
    }

    @Test("Differences within epsilon are equal")
    func withinEpsilonMatches() {
        let letter = PDFPageSize.letter
        let almostSame = PDFPageSize(width: .init(value: 8.5, unit: .inches),
                                      height: .init(value: 11.00001, unit: .inches))
        #expect(letter == almostSame)
    }

    @Test("A4 and Letter are distinct")
    func a4NotLetter() {
        #expect(PDFPageSize.a4 != PDFPageSize.letter)
    }

    private static func testFormatting(locale: Locale) {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1

        let a4Width = formatter.string(from: Measurement(value: 21, unit: UnitLength.centimeters))
        let a4Height = formatter.string(from: Measurement(value: 29.7, unit: UnitLength.centimeters))
        let letterWidth = formatter.string(from: Measurement(value: 8.5, unit: UnitLength.inches))
        let letterHeight = formatter.string(from: Measurement(value: 11, unit: UnitLength.inches))
        let customUnit: UnitLength = locale.measurementSystem == .metric ? .centimeters : .inches
        let customWidth = Measurement(value: 12, unit: UnitLength.feet).converted(to: customUnit)
        let customWidthString = formatter.string(from: customWidth)
        let customHeight = Measurement(value: 23, unit: UnitLength.fathoms).converted(to: customUnit)
        let customHeightString = formatter.string(from: customHeight)
        let customPageSize = PDFPageSize(width: customWidth, height: customHeight)

        #expect(PDFPageSize.a4.formatted(locale: locale) == "A4 (\(a4Width) ⨉ \(a4Height))")
        #expect(PDFPageSize.letter.formatted(locale: locale) == "Letter (\(letterWidth) ⨉ \(letterHeight))")
        #expect(customPageSize.formatted(locale: locale) == "\(customWidthString) ⨉ \(customHeightString)")
    }

    @Test func formatting() throws {
        Self.testFormatting(locale: Locale(identifier: "en-US"))
        Self.testFormatting(locale: Locale(identifier: "en-UK"))
        Self.testFormatting(locale: Locale(identifier: "de-DE"))
    }
}
