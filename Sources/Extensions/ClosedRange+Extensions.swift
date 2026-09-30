extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        Swift.min(
            Swift.max(value, lowerBound),
            upperBound
        )
    }
}
