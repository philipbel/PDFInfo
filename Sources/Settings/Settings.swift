import CoreGraphics
import Foundation

enum Settings {
    static let previewFontSizeRange = CGFloat(10)...CGFloat(50)

    static let previewText = Setting(key: "previewText",
                                     default: "The quick brown fox jumps over the lazy dog")
    static let previewFontSize = Setting(key: "previewFontSize", default: CGFloat(20))
}


extension UserDefaults {
    @objc
    dynamic var previewText: String {
        return string(forKey: Settings.previewText.key) ?? Settings.previewText.default
    }

    @objc
    dynamic var previewFontSize: CGFloat {
        return min(
            max(double(forKey: Settings.previewFontSize.key), Settings.previewFontSizeRange.lowerBound),
            Settings.previewFontSizeRange.upperBound
        )
    }
}
