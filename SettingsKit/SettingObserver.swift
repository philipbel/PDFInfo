private import Foundation
private import Combine


internal nonisolated final class SettingObserver<Value: SettingValue, Validator: SettingValidator<Value>>: NSObject {
    let subject: CurrentValueSubject<Value, Never>
    private let defaults: UserDefaults
    private let setting: Setting<Value, Validator>

    init(
        defaults: UserDefaults,
        setting: Setting<Value, Validator>,
    ) {
        self.subject = CurrentValueSubject(defaults.value(for: setting))
        self.defaults = defaults
        self.setting = setting

        super.init()

        defaults.addObserver(self, forKeyPath: setting.key, options: [], context: nil)
    }

    deinit {
        defaults.removeObserver(self, forKeyPath: setting.key)
    }

    override nonisolated func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == setting.key else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        subject.send(defaults.value(for: setting))
    }

}
