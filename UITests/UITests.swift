import XCTest

final class UITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private static func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // UITests/
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("Tests/test-pdfs/\(name).pdf")
    }

    private func findOpenPanel() -> XCUIElement {
        let panel = app.windows["Open"]
        XCTAssert(panel.waitForExistence(), "Open panel not found")
        return panel
    }

    /// The app has no writable/"Untitled" document type, so DocumentGroup shows the
    /// standard Open panel automatically at launch. Cmd+Shift+G "Go to Folder" lets us
    /// jump straight to a fixture instead of automating Finder-style column navigation.
    @discardableResult
    private func launchAndOpen(_ fixtureName: String) -> XCUIElement {
        app.launch()

        let openPanel = findOpenPanel()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let goToField = openPanel.textFields.firstMatch
        XCTAssertTrue(goToField.waitForExistence(), "Go to Folder field did not appear")
        goToField.typeText(Self.fixtureURL(fixtureName).path)
        goToField.typeText("\n")

        let openButton = openPanel.buttons["Open"]
        XCTAssertTrue(openButton.waitForExistence(), "Open button did not appear")
        openButton.click()

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(), "Document window did not appear")
        return window
    }

    // MARK: - Opening documents
    @MainActor
    func testOpeningDocumentShowsFontTable() throws {
        let window = launchAndOpen("multi_font_mixed")

        let table = window.tables["fonts-table"].firstMatch
        XCTAssertTrue(table.waitForExistence())
        XCTAssertTrue(table.staticTexts["Helvetica"].exists)
        XCTAssertTrue(table.staticTexts["Times-Roman"].exists)
    }

    @MainActor
    func testEncryptedDocumentOpensWithEmptyFontTable() throws {
        let window = launchAndOpen("encrypted")

        let table = window.tables["fonts-table"].firstMatch
        XCTAssertTrue(table.waitForExistence())
        XCTAssertEqual(table.tableRows.count, 0)
    }

    @MainActor
    func testMalformedDocumentShowsErrorWithoutCrashing() throws {
        app.launch()

        let openPanel = findOpenPanel()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let goToField = openPanel.textFields.firstMatch
        XCTAssertTrue(goToField.waitForExistence())
        goToField.typeText(Self.fixtureURL("malformed_truncated").path)
        goToField.typeText("\n")
        openPanel.buttons["Open"].click()

        XCTAssertTrue(app.dialogs.firstMatch.waitForExistence(),
                      "Expected an error alert for a malformed PDF")
        XCTAssertEqual(app.state, .runningForeground, "App should not crash on a malformed PDF")
    }

    // MARK: - Inspector

    @MainActor
    func testInspectorTogglesVisibility() throws {
        let window = launchAndOpen("metadata_populated")

        let inspectorButton = window.checkBoxes["Inspector"]
        XCTAssert(inspectorButton.exists, "Inspector button doesn't exist")
        if let v = inspectorButton.value as? Bool, v == false {
            inspectorButton.click()
            XCTAssert(inspectorButton.value as? Bool == true, "Inspector button is checked")
        }
        let versionLabel = window.staticTexts["PDF Version:"]
        XCTAssertTrue(versionLabel.exists, "Inspector should be visible by default")

        inspectorButton.click()
        XCTAssert(inspectorButton.value as? Bool == false, "Inspector button is not checked")
    }

    @MainActor
    func testDocumentInfoDisplaysMetadataAndPageSize() throws {
        let window = launchAndOpen("metadata_populated")

        let inspectorButton = window.checkBoxes["Inspector"]
        if let v = inspectorButton.value as? Bool, v == false {
            inspectorButton.click()
            XCTAssert(inspectorButton.value as? Bool == true, "Inspector button is checked")
        }

        XCTAssertTrue(window.staticTexts["Fixture Title"].waitForExistence())
        XCTAssertTrue(window.staticTexts["Phil"].exists)

        let pageSize = window.staticTexts.matching(identifier: "page_size").firstMatch
        XCTAssertTrue(pageSize.exists)

        XCTAssert(pageSize.value as? String == "Letter (8.5″ ⨉ 11″)")
    }

    @MainActor
    func testFontPreview() throws {
        let window = launchAndOpen("multi_font_mixed")

        let table = window.tables["fonts-table"].firstMatch
        XCTAssertTrue(table.waitForExistence())
        XCTAssertTrue(table.staticTexts["Helvetica"].exists)
        let previewButton = window.buttons["preview-Helvetica"]
        XCTAssert(previewButton.waitForExistence())
        previewButton.click()

        let previewWindow = app.windows["Font Preview: Helvetica"]
        XCTAssertTrue(previewWindow.waitForExistence(),
                      "Font preview window did not open")
        XCTAssertTrue(previewWindow.staticTexts["Helvetica"].exists,
                      "Preview should display the font name")
    }
}
