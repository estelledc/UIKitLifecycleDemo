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

        let textField = app.textFields["titleTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "The detail text field should be visible.")
        textField.tap()
        textField.clearAndTypeText("Buy groceries today")

        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "The Save button should be visible.")
        saveButton.tap()

        let editedTitle = app.staticTexts["Buy groceries today"].firstMatch
        XCTAssertTrue(editedTitle.waitForExistence(timeout: 5), "The edited title should appear after Save.")
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
