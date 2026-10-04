import Foundation

nonisolated public protocol SettingValue: Equatable, Sendable { }

extension Bool: SettingValue { }
extension Int: SettingValue { }
extension Float: SettingValue { }
extension Double: SettingValue { }
extension String: SettingValue { }
extension Date: SettingValue { }
extension Data: SettingValue { }
extension Array: SettingValue where Element: SettingValue { }
extension Dictionary: SettingValue where Key == String, Value: SettingValue { }
