// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import XCTest

extension XCUIElement {
    static let defeaultTimeout: TimeInterval = 1

    func waitForExistence() -> Bool {
        waitForExistence(timeout: Self.defeaultTimeout)
    }

    func waitForNonExistence() -> Bool {
        waitForNonExistence(timeout: Self.defeaultTimeout)
    }
}
