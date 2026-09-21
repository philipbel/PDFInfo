import Foundation

nonisolated struct PDFPageSize: Codable, Equatable, Sendable {
    private static let epsilon = 0.0001

    let width: Measurement<UnitLength>
    let height: Measurement<UnitLength>

    static let a4: Self = .init(width: .init(value: 21, unit: .centimeters),
                                height: .init(value: 29.7, unit: .centimeters))
    static let letter: Self = .init(width: .init(value: 8.5, unit: .inches),
                                    height: .init(value: 11, unit: .inches))

    func formatted(locale: Locale = .current) -> String {
        let formatter = Self.makeFormatter(locale: locale)

        if self == Self.a4 {
            let paperSize = Self.formatPageSize(width: width, height: height, formatter: formatter, unit: nil)
            return "A4 (\(paperSize))"
        } else if self == Self.letter {
            let paperSize = Self.formatPageSize(width: width, height: height, formatter: formatter, unit: nil)
            return "Letter (\(paperSize))"
        } else {
            // Pick units based on the measurement system
            let unit: UnitLength = locale.measurementSystem == .metric ? .centimeters : .inches
            return Self.formatPageSize(width: width, height: height, formatter: formatter, unit: unit)
        }
    }

    private static func makeFormatter(locale: Locale) -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }

    private static func formatPageSize(
        width: Measurement<UnitLength>,
        height: Measurement<UnitLength>,
        formatter: MeasurementFormatter,
        unit: UnitLength?
    ) -> String {
        let w = if let unit {
            formatter.string(from: width.converted(to: unit))
        } else {
            formatter.string(from: width)
        }
        let h = if let unit {
            formatter.string(from: height.converted(to: unit))
        } else {
            formatter.string(from: height)
        }
        return "\(w) ⨉ \(h)"
    }

    static func == (lhs: PDFPageSize, rhs: PDFPageSize) -> Bool {
        let lhsWidth = lhs.width.converted(to: rhs.width.unit)
        let lhsHeight = lhs.height.converted(to: rhs.height.unit)
        return abs(lhsWidth.value - rhs.width.value) < Self.epsilon && abs(lhsHeight.value - rhs.height.value) < epsilon
    }
}
