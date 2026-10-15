private import Foundation


nonisolated public struct Setting<Value: SettingValue, Validator: SettingValidator<Value>>: Sendable {
    public let key: String
    public let `default`: Value
    public let validator: Validator

    public init(key: String, `default`: Value, validator: Validator) {
        assert(validator.validate(value: `default`, default: `default`) == `default`,
               "Default value \(`default`) for setting '\(key)' is invalid")

        self.key = key
        self.default = `default`
        self.validator = validator
    }
}


nonisolated extension Setting where Validator == NoOpSettingValidator<Value> {
    public init(key: String, `default`: Value) {
        self.init(key: key, default: `default`, validator: NoOpSettingValidator())
    }
}


nonisolated extension Setting where Validator == RangeValidator<Value> {
    public init(key: String, `default`: Value, in range: ClosedRange<Value>) {
        self.init(key: key, default: `default`, validator: RangeValidator(range: range))
    }
}


