// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

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
