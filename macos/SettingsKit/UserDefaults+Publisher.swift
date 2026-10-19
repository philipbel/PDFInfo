// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

@_exported public import Foundation
@_exported public import Combine


nonisolated extension UserDefaults {
    public func publisher<Value: SettingValue, Validator: SettingValidator<Value>>(
        for keyPath: KeyPath<UserDefaults.Type, Setting<Value, Validator>>
    ) -> AnyPublisher<Value, Never> {
        return Deferred { [self] in
            let setting = UserDefaults.self[keyPath: keyPath]
            let observer = SettingObserver(defaults: self, setting: setting)
            return observer.subject.handleEvents(receiveCancel: {
                withExtendedLifetime(observer, { })
            })
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
