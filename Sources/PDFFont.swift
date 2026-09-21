import SwiftUI
import UniformTypeIdentifiers

nonisolated struct PDFFont: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let subtype: String
    let embedded: Bool
    let subset: Bool
}
