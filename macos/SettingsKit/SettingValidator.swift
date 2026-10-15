nonisolated public protocol SettingValidator<Value>: Sendable {
    associatedtype Value: SettingValue

    func validate(value: Value, default: Value) -> Value
}
