PROJECT := UIKitLifecycleDemo.xcodeproj
SCHEME := UIKitLifecycleDemo
CONFIGURATION := Debug
SIMULATOR_NAME ?= iPhone 17 Pro
DESTINATION ?= platform=iOS Simulator,name=$(SIMULATOR_NAME),OS=latest
DERIVED_DATA := .DerivedData
LOG_DIR := .build_logs
BUILD_LOG := $(LOG_DIR)/xcodebuild.log
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/UIKitLifecycleDemo.app
BUNDLE_ID := com.example.UIKitLifecycleDemo
XCBEAUTIFY ?= xcbeautify

.PHONY: build test-ui run open logs clean verify-showcase

build:
	@mkdir -p "$(LOG_DIR)"
	@set -o pipefail; \
	if command -v "$(XCBEAUTIFY)" >/dev/null 2>&1; then \
		xcodebuild \
			-project "$(PROJECT)" \
			-scheme "$(SCHEME)" \
			-configuration "$(CONFIGURATION)" \
			-destination "$(DESTINATION)" \
			-derivedDataPath "$(DERIVED_DATA)" \
			build 2>&1 | tee "$(BUILD_LOG)" | "$(XCBEAUTIFY)"; \
	else \
		echo "xcbeautify not found; showing raw xcodebuild output."; \
		xcodebuild \
			-project "$(PROJECT)" \
			-scheme "$(SCHEME)" \
			-configuration "$(CONFIGURATION)" \
			-destination "$(DESTINATION)" \
			-derivedDataPath "$(DERIVED_DATA)" \
			build 2>&1 | tee "$(BUILD_LOG)"; \
	fi

run: build
	@xcrun simctl boot "$(SIMULATOR_NAME)" >/dev/null 2>&1 || true
	@xcrun simctl bootstatus booted -b
	@xcrun simctl install booted "$(APP_PATH)"
	@xcrun simctl launch booted "$(BUNDLE_ID)"

test-ui:
	@mkdir -p "$(LOG_DIR)"
	@set -o pipefail; \
	if command -v "$(XCBEAUTIFY)" >/dev/null 2>&1; then \
		xcodebuild \
			-project "$(PROJECT)" \
			-scheme "$(SCHEME)" \
			-configuration "$(CONFIGURATION)" \
			-destination "$(DESTINATION)" \
			-derivedDataPath "$(DERIVED_DATA)" \
			test 2>&1 | tee "$(BUILD_LOG)" | "$(XCBEAUTIFY)"; \
	else \
		echo "xcbeautify not found; showing raw xcodebuild output."; \
		xcodebuild \
			-project "$(PROJECT)" \
			-scheme "$(SCHEME)" \
			-configuration "$(CONFIGURATION)" \
			-destination "$(DESTINATION)" \
			-derivedDataPath "$(DERIVED_DATA)" \
			test 2>&1 | tee "$(BUILD_LOG)"; \
	fi

open:
	@open "$(PROJECT)"

logs:
	@if [ -f "$(BUILD_LOG)" ]; then \
		awk '{ lines[NR % 120] = $$0 } END { start = NR > 120 ? NR - 119 : 1; for (i = start; i <= NR; i++) print lines[i % 120] }' "$(BUILD_LOG)"; \
	else \
		echo "No build log found. Run make build first."; \
	fi

clean:
	@xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -derivedDataPath "$(DERIVED_DATA)" clean >/dev/null
	@rm -rf "$(DERIVED_DATA)" "$(LOG_DIR)"

verify-showcase:
	@python3 scripts/audit-showcase.py
	@python3 scripts/verify-actions-pinned.py
