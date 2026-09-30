import Foundation

extension UserDefaults {
    @objc
    dynamic var previewText: String {
        get {
            string(forKey: Settings.previewText.key) ?? Settings.previewText.default
        }
        set {
            let newValue = if newValue.isEmpty {
                Settings.previewText.default
            } else {
                newValue
            }
            set(newValue, forKey: Settings.previewText.key)
        }
    }

    @objc
    dynamic var previewFontSize: Int {
        get {
            let value = integer(forKey: Settings.previewFontSize.key)
            return if Settings.previewFontSizeRange.contains(value) {
                value
            } else {
                Settings.previewFontSize.default
            }
        }
        set {
            if Settings.previewFontSizeRange.contains(newValue) {
                set(newValue, forKey: Settings.previewFontSize.key)
            } else {
                set(Settings.previewFontSize.default, forKey: Settings.previewFontSize.key)
            }
        }
    }
}
