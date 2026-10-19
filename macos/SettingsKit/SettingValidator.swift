// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

nonisolated public protocol SettingValidator<Value>: Sendable {
    associatedtype Value: SettingValue

    func validate(value: Value, default: Value) -> Value
}
