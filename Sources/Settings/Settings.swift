import CoreGraphics
import Foundation

enum Settings {
    static let previewFontSizeRange = 10...50

    static let previewText = Setting(key: "previewText",
                                     default: "The quick brown fox jumps over the lazy dog")
    static let previewFontSize = Setting(key: "previewFontSize", default: 20)
}
