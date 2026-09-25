internal import CoreGraphics

internal enum PDFKitError: Error, CustomStringConvertible {
    case corruptedObject(message: String)
    case invalidFontType(message: String)

    static func makeInvalidFontTypeError(expected: [PDFFontSubtype], actual: PDFFontSubtype) -> PDFKitError {
        Self.invalidFontType(message: "expected \(expected), got \(actual)")
    }
}


// MARK: CustomStringConvertible

extension PDFKitError {
    var description: String {
        let message = switch self {
        case .corruptedObject(let m):
            "corrupted object: \(m)"
        case .invalidFontType(let m):
            "invalid font type: \(m)"
        }
        return "PDFKitError: " + message
    }
}
