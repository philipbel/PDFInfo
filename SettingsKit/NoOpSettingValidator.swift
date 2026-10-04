nonisolated public struct NoOpSettingValidator<Value: SettingValue>: SettingValidator<Value> {
    public init() {
    }

    public func validate(value: Value, default _: Value) -> Value {
        value
    }
}


nonisolated extension SettingValidator {
    public static func noOp<V: SettingValue>() ->  NoOpSettingValidator<V> where Self == NoOpSettingValidator<V>{
        NoOpSettingValidator()
    }
}
