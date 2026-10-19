// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        Swift.min(
            Swift.max(value, lowerBound),
            upperBound
        )
    }
}
