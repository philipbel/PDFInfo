// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

public import Foundation


nonisolated extension UserDefaults {
    public func value<Value: SettingValue, Validator: SettingValidator<Value>>(
        for setting: Setting<Value, Validator>
    ) -> Value {
        let v = self.object(forKey: setting.key) as? Value ?? setting.default
        return setting.validator.validate(value: v, default: setting.default)
    }

    public func set<Value: SettingValue, Validator: SettingValidator<Value>>(
        _ value: Value,
        for setting: Setting<Value, Validator>
    ) {
        let value = setting.validator.validate(value: value, default: setting.default)
        guard value != setting.default else {
            removeObject(forKey: setting.key)
            return
        }
        self.set(value, forKey: setting.key)
    }

    public subscript<Value: SettingValue, Validator: SettingValidator<Value>>(
        _ keyPath: KeyPath<UserDefaults.Type, Setting<Value, Validator>>
    ) -> Value {
        get {
            let setting = UserDefaults.self[keyPath: keyPath]
            return value(for: setting)
        }
        set {
            let setting = UserDefaults.self[keyPath: keyPath]
            set(newValue, for: setting)
        }
    }
}
