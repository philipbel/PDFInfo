internal enum CGPDFError: Error, CustomStringConvertible {
    case typeError(message: String)

    var description: String {
        switch self {
        case .typeError(let message):
            "TypeError(\(message))"
        }
    }
}
