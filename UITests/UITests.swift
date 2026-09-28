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

    // MARK: - Opening documents
    @MainActor
    func testOpeningDocumentShowsFontTable() throws {
        let window = TestUtil.launchApp(app, openingPDFNamed: "multi_font_mixed")

        let table = window.tables["fonts-table"].firstMatch
        XCTAssertTrue(table.waitForExistence())
        XCTAssertTrue(table.staticTexts["Helvetica"].exists)
        XCTAssertTrue(table.staticTexts["Times-Roman"].exists)
    }

    @MainActor
    func testEncryptedDocumentOpensWithEmptyFontTable() throws {
        let window = TestUtil.launchApp(app, openingPDFNamed: "encrypted")

        let table = window.tables["fonts-table"].firstMatch
        XCTAssertTrue(table.waitForExistence())
        XCTAssertEqual(table.tableRows.count, 0)
    }

    @MainActor
    func testMalformedDocumentShowsErrorWithoutCrashing() throws {
        app.launch()

        let openPanel = TestUtil.findOpenPanel(inApp: app)
        app.typeKey("g", modifierFlags: [.command, .shift])
        let goToField = openPanel.textFields.firstMatch
        XCTAssertTrue(goToField.waitForExistence())
        goToField.typeText(TestUtil.urlForTestPDF("malformed_truncated").path)
        goToField.typeText("\n")
        openPanel.buttons["Open"].click()

        XCTAssertTrue(app.dialogs.firstMatch.waitForExistence(),
                      "Expected an error alert for a malformed PDF")
        XCTAssertEqual(app.state, .runningForeground, "App should not crash on a malformed PDF")
    }

    // MARK: - Inspector

    @MainActor
    func testInspectorTogglesVisibility() throws {
        let window = TestUtil.launchApp(app, openingPDFNamed: "metadata_populated")

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
        let window = TestUtil.launchApp(app, openingPDFNamed: "metadata_populated")

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
        let window = TestUtil.launchApp(app, openingPDFNamed: "multi_font_mixed")

        let table = window.tables["fonts-table"].firstMatch
        let previewButton = table.buttons.matching(identifier: "Preview font").element(boundBy: 0)
        previewButton.click()
        let previewWindow1 = app.windows["Font Preview"]
        XCTAssert(previewWindow1.waitForExistence(), "Quick Look button should show font preview window")

        let previewWindowCloseButton1 = previewWindow1.buttons["_XCUI:CloseWindow"].firstMatch
        previewWindowCloseButton1.click()
        XCTAssert(previewWindow1.waitForNonExistence())

        let cell = table.cells.containing(.staticText, identifier: "Times-Roman").firstMatch
        cell.doubleClick()
        let previewWindow2 = app.windows["Font Preview"]
        XCTAssert(previewWindow2.waitForExistence(), "Double clicking on a table row should show font preview window")
    }

    @MainActor
    func testSettings() throws {
        let app = XCUIApplication()
        app.activate()

        app.typeKey(",", modifierFlags: .command)
        let settingsWindow1 = app.windows["Settings"].firstMatch
        XCTAssert(settingsWindow1.waitForExistence())
        settingsWindow1.buttons["_XCUI:CloseWindow"].firstMatch.click()
        XCTAssert(settingsWindow1.waitForNonExistence())

        app.menuItems["Settings…"].firstMatch.click()
        let settingsWindow2 = app.windows["Settings"].firstMatch
        XCTAssert(settingsWindow2.waitForExistence())
        let fontSizeTextField = app.textFields["font-size-text-field"].firstMatch
        XCTAssert(fontSizeTextField.exists)
        XCTAssert(fontSizeTextField.value as? String == "20")

        let stepper = app.steppers["font-size-stepper"]
        XCTAssert(stepper.exists)

        stepper.incrementArrows.firstMatch.click()
        XCTAssert(fontSizeTextField.value as? String == "21")
        stepper.decrementArrows.firstMatch.click()
        XCTAssert(fontSizeTextField.value as? String == "20")
    }
}
