// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

nonisolated public struct EmptyStringValidator: SettingValidator<String> {
    private let trim: Bool

    public init(trim: Bool) {
        self.trim = trim
    }

    public func validate(value: Value, default: Value) -> Value {
        if trim {
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? `default` : value
        } else {
            return value.isEmpty ? `default` : value
        }
    }
}


nonisolated extension SettingValidator where Self == EmptyStringValidator {
    public static func emptyString(trim: Bool = true) -> EmptyStringValidator {
        EmptyStringValidator(trim: trim)
    }
}
