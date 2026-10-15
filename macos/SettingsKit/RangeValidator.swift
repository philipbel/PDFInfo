nonisolated public struct RangeValidator<Value: SettingValue>: SettingValidator<Value> where Value: Comparable {
    public let range: ClosedRange<Value>

    init(range: ClosedRange<Value>) {
        self.range = range
    }

    public func validate(value: Value, default _: Value) -> Value {
        if value > range.upperBound {
            return range.upperBound
        } else if value < range.lowerBound {
            return range.lowerBound
        } else {
            return value
        }
    }
}


nonisolated extension SettingValidator {
    public static func range<V: SettingValue & Comparable>(
        _ range: ClosedRange<V>
    ) -> RangeValidator<V> where Self == RangeValidator<V> {
        RangeValidator(range: range)
    }
}
