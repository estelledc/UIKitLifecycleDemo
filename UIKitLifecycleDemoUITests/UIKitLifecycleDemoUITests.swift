import XCTest

final class UIKitLifecycleDemoUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testEditFirstReminderTitle() throws {
    let app = XCUIApplication()
    app.launch()

    let firstCell = app.cells["reminderCell_buy-groceries"]
    XCTAssertTrue(
      firstCell.waitForExistence(timeout: 5), "The initial reminder cell should be visible.")
    XCTAssertTrue(firstCell.label.contains("Buy groceries"))
    firstCell.tap()

    let useExampleTitleButton = app.buttons["useExampleTitleButton"]
    XCTAssertTrue(
      useExampleTitleButton.waitForExistence(timeout: 5),
      "The example title helper should be visible.")
    useExampleTitleButton.tap()

    let saveButton = app.buttons["saveButton"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "The Save button should be visible.")
    saveButton.tap()

    let editedCell = app.cells["reminderCell_buy-groceries"]
    XCTAssertTrue(editedCell.waitForExistence(timeout: 5))
    expectation(
      for: NSPredicate(format: "label CONTAINS %@", "Buy groceries today"),
      evaluatedWith: editedCell)
    waitForExpectations(timeout: 5)
  }

  func testOpenLogsAndGuide() throws {
    let app = XCUIApplication()
    app.launch()

    openLearnMenuItem("Logs", in: app)
    XCTAssertTrue(
      app.tables["demoLogPanel"].waitForExistence(timeout: 5), "The in-app log panel should open.")
    XCTAssertTrue(
      app.buttons["logFilterButton"].waitForExistence(timeout: 5),
      "The log filter should be visible.")
    XCTAssertTrue(
      app.switches["onlyKeyEventsSwitch"].waitForExistence(timeout: 5),
      "The key events switch should be visible.")
    let pauseButton = app.buttons["pauseLogsButton"]
    XCTAssertTrue(
      pauseButton.waitForExistence(timeout: 5),
      "The pause scroll button should be addressable by a stable identifier.")
    XCTAssertEqual(pauseButton.label, "Pause Scroll")
    pauseButton.tap()
    expectation(
      for: NSPredicate(format: "label == %@", "Resume Scroll"), evaluatedWith: pauseButton)
    waitForExpectations(timeout: 5)
    pauseButton.tap()
    expectation(
      for: NSPredicate(format: "label == %@", "Pause Scroll"), evaluatedWith: pauseButton)
    waitForExpectations(timeout: 5)
    app.buttons["closeLogsButton"].tap()

    openLearnMenuItem("Guide", in: app)
    XCTAssertTrue(
      app.scrollViews["guidedExperimentView"].waitForExistence(timeout: 5),
      "The guided experiment view should open.")
    XCTAssertEqual(app.staticTexts["guideProgress"].label, "1 / 9")
    XCTAssertTrue(
      app.staticTexts["guideSourceCue"].label.contains("ReminderListViewController.swift"))
    XCTAssertTrue(app.staticTexts["guideXcodeAction"].label.contains("调用栈"))
    XCTAssertFalse(app.staticTexts["UIKit Core Tour"].exists)
    XCTAssertFalse(app.staticTexts["guideGoal"].exists)
    XCTAssertFalse(app.staticTexts["操作前预测"].exists)
    XCTAssertFalse(app.staticTexts["预期日志"].exists)
    XCTAssertFalse(app.staticTexts["完成后问题"].exists)
    XCTAssertFalse(app.staticTexts["一句话复盘"].exists)
    XCTAssertFalse(app.staticTexts["胜利条件"].exists)

    app.buttons["guideNextButton"].tap()
    XCTAssertEqual(app.staticTexts["guideProgress"].label, "2 / 9")
    XCTAssertTrue(app.staticTexts["guideStepTitle"].label.contains("点击 cell"))
  }

  private func openLearnMenuItem(_ title: String, in app: XCUIApplication) {
    let learnButton =
      app.buttons["learnButton"].exists ? app.buttons["learnButton"] : app.buttons["Learn"]
    XCTAssertTrue(learnButton.waitForExistence(timeout: 5), "The Learn menu should be visible.")
    learnButton.tap()

    let menuItem = app.buttons[title]
    XCTAssertTrue(
      menuItem.waitForExistence(timeout: 5), "The \(title) menu item should be visible.")
    menuItem.tap()
  }
}

extension XCUIElement {
  fileprivate func clearAndTypeText(_ text: String) {
    guard let currentValue = value as? String else {
      typeText(text)
      return
    }

    let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
    typeText(deleteString)
    typeText(text)
  }
}
