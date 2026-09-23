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
