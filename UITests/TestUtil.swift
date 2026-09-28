import Foundation
import XCTest
import UniformTypeIdentifiers


enum TestUtil {
    static func sourceRootDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // UITests/
            .deletingLastPathComponent()   // source root
    }

    static func testPDFDirectory() -> URL {
        sourceRootDirectory()
            .appendingPathComponent("test-pdfs", isDirectory: true)
    }

    static func urlForTestPDF(_ name: String) -> URL {
        testPDFDirectory().appendingPathComponent("\(name).pdf")
    }

    static func screenshot(of element: XCUIElement, name: String) throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(components: "screenshot", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let url = tempDir.appendingPathComponent(name, conformingTo: .png)
        try element.screenshot().pngRepresentation.write(to: url)
        print("screenshot '\(name)' saved to \(url.path())")
    }

    static func findOpenPanel(inApp app: XCUIApplication) -> XCUIElement {
        let panel = app.windows["Open"]
        XCTAssert(panel.waitForExistence(), "Open panel not found")
        return panel
    }

    @discardableResult
    static func launchApp(_ app: XCUIApplication, openingPDFNamed pdfName: String) -> XCUIElement {
        app.launch()

        let openPanel = Self.findOpenPanel(inApp: app)
        app.typeKey("g", modifierFlags: [.command, .shift])
        let goToField = openPanel.textFields.firstMatch
        XCTAssertTrue(goToField.waitForExistence(), "Go to Folder field did not appear")
        goToField.typeText(Self.urlForTestPDF(pdfName).path)
        goToField.typeText("\n")

        let openButton = openPanel.buttons["Open"]
        XCTAssertTrue(openButton.waitForExistence(), "Open button did not appear")
        openButton.click()

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(), "Document window did not appear")
        return window
    }
}
