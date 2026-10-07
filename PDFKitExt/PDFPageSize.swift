public import Foundation
internal import PDFKit


public struct PDFPageSize: Codable, Equatable, Sendable {
    public enum Orientation: String, Sendable, Codable {
        case portrait = "portrait"
        case landscape = "landscape"

        public var displayName: String {
            switch self {
            case .portrait:
                String(localized: "Portrait", bundle: #bundle)
            case .landscape:
                String(localized: "Landscape", bundle: #bundle)
            }
        }
    }

    private static let epsilon = 0.01

    public let width: Measurement<UnitLength>
    public let height: Measurement<UnitLength>
    public var orientation: Orientation {
        return if width <= height {
            .portrait
        } else {
            .landscape
        }
    }

    public static let a4: Self = .init(width: .init(value: 21, unit: .centimeters),
                                       height: .init(value: 29.7, unit: .centimeters))
    public static let letter: Self = .init(width: .init(value: 8.5, unit: .inches),
                                           height: .init(value: 11, unit: .inches))

    internal init(width: Measurement<UnitLength>, height: Measurement<UnitLength>) {
        self.width = width
        self.height = height
    }

    internal init?(fromPage page: PDFPage) {
        guard let pageRef = page.pageRef else {
            return nil
        }
        let box = pageRef.getBoxRect(.cropBox) // in points (1/72")
        var width = Measurement(value: box.width / 72, unit: UnitLength.inches)
        var height = Measurement(value: box.height / 72, unit: UnitLength.inches)
        if page.rotation == 90 || page.rotation == 270 {
            (width, height) = (height, width)
        }
        self.init(width: width, height: height)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = Self.makeFormatter(locale: locale)

        let pageSize = if orientation == .portrait {
            self
        } else {
            PDFPageSize(width: height, height: width)
        }
        if pageSize == Self.a4 {
            let paperSize = Self.formatPageSize(self, formatter: formatter, unit: Self.a4.width.unit)
            return String(localized: "A4 (\(paperSize), \(orientation.displayName))", bundle: #bundle)
        } else if pageSize == Self.letter {
            let paperSize = Self.formatPageSize(self, formatter: formatter, unit: Self.letter.width.unit)
            return String(localized: "Letter (\(paperSize), \(orientation.displayName))", bundle: #bundle)
        } else {
            // Pick units based on the measurement system
            let unit: UnitLength = locale.measurementSystem == .us ? .inches : .centimeters
            return Self.formatPageSize(self, formatter: formatter, unit: unit)
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
        _ pageSize: PDFPageSize,
        formatter: MeasurementFormatter,
        unit: UnitLength
    ) -> String {
        let w = formatter.string(from: pageSize.width.converted(to: unit))
        let h = formatter.string(from: pageSize.height.converted(to: unit))
        return "\(w) ⨉ \(h)"
    }

    public static func == (lhs: PDFPageSize, rhs: PDFPageSize) -> Bool {
        let lhsWidth = lhs.width.converted(to: .centimeters).value
        let lhsHeight = lhs.height.converted(to: .centimeters).value
        let rhsWidth = rhs.width.converted(to: .centimeters).value
        let rhsHeight = rhs.height.converted(to: .centimeters).value
        return abs(lhsWidth - rhsWidth) < epsilon && abs(lhsHeight - rhsHeight) < epsilon
    }
}
