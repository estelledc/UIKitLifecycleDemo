import XCTest

final class UIKitLifecycleDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEditFirstReminderTitle() throws {
        let app = XCUIApplication()
        app.launch()

        let firstTitle = app.staticTexts["Buy groceries"].firstMatch
        XCTAssertTrue(firstTitle.waitForExistence(timeout: 5), "The initial reminder should be visible.")
        firstTitle.tap()

        let useExampleTitleButton = app.buttons["useExampleTitleButton"]
        XCTAssertTrue(useExampleTitleButton.waitForExistence(timeout: 5), "The example title helper should be visible.")
        useExampleTitleButton.tap()

        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "The Save button should be visible.")
        saveButton.tap()

        let editedTitle = app.staticTexts["Buy groceries today"].firstMatch
        XCTAssertTrue(editedTitle.waitForExistence(timeout: 5), "The edited title should appear after Save.")
    }

    func testOpenLogsAndGuide() throws {
        let app = XCUIApplication()
        app.launch()

        openLearnMenuItem("Logs", in: app)
        XCTAssertTrue(app.tables["demoLogPanel"].waitForExistence(timeout: 5), "The in-app log panel should open.")
        XCTAssertTrue(app.buttons["logFilterButton"].waitForExistence(timeout: 5), "The log filter should be visible.")
        XCTAssertTrue(app.switches["onlyKeyEventsSwitch"].waitForExistence(timeout: 5), "The key events switch should be visible.")
        app.buttons["closeLogsButton"].tap()

        openLearnMenuItem("Guide", in: app)
        XCTAssertTrue(app.scrollViews["guidedExperimentView"].waitForExistence(timeout: 5), "The guided experiment view should open.")
        XCTAssertTrue(app.staticTexts["5-minute UIKit Core Tour"].waitForExistence(timeout: 5), "The core tour title should be visible.")
        XCTAssertTrue(app.staticTexts["Step 1: 启动生命周期"].waitForExistence(timeout: 5), "The first guide step should be visible.")
    }

    private func openLearnMenuItem(_ title: String, in app: XCUIApplication) {
        let learnButton = app.buttons["learnButton"].exists ? app.buttons["learnButton"] : app.buttons["Learn"]
        XCTAssertTrue(learnButton.waitForExistence(timeout: 5), "The Learn menu should be visible.")
        learnButton.tap()

        let menuItem = app.buttons[title]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 5), "The \(title) menu item should be visible.")
        menuItem.tap()
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let currentValue = value as? String else {
            typeText(text)
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
