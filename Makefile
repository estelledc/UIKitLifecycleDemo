PROJECT := UIKitLifecycleDemo.xcodeproj
SCHEME := UIKitLifecycleDemo
CONFIGURATION := Debug
SIMULATOR_NAME ?= iPhone 17 Pro
SIMULATOR_OS ?= $(shell xcrun --sdk iphonesimulator --show-sdk-version)
DESTINATION ?= platform=iOS Simulator,name=$(SIMULATOR_NAME),OS=$(SIMULATOR_OS)
SIMULATOR_UDID ?= $(shell xcrun simctl list devices available 2>/dev/null | awk -v runtime="-- iOS $(SIMULATOR_OS) --" -v device="$(SIMULATOR_NAME)" '\
	$$0 == runtime { in_runtime = 1; next } \
	in_runtime && /^-- / { exit } \
	in_runtime { \
		line = $$0; sub(/^[[:space:]]*/, "", line); prefix = device " ("; \
		if (index(line, prefix) == 1) { \
			line = substr(line, length(prefix) + 1); print substr(line, 1, index(line, ")") - 1); exit \
		} \
	}')
SIMULATOR_TARGET ?= $(SIMULATOR_UDID)
DERIVED_DATA := .DerivedData
LOG_DIR := .build_logs
BUILD_LOG := $(LOG_DIR)/xcodebuild.log
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/UIKitLifecycleDemo.app
BUNDLE_ID := com.example.UIKitLifecycleDemo
XCBEAUTIFY ?= xcbeautify

.PHONY: prepare-local-caches build build-ci build-release test-ui run open logs clean audit-project verify-showcase public-scan check release-check

prepare-local-caches:
	@root=$$(pwd -P); \
	marker="$(DERIVED_DATA)/.uikit-lifecycle-demo-workspace-root"; \
	if [ -d "$(DERIVED_DATA)" ] && { [ ! -f "$$marker" ] || [ "$$(cat "$$marker")" != "$$root" ]; }; then \
		echo "Resetting relocated build cache: $(DERIVED_DATA)"; \
		rm -rf "$(DERIVED_DATA)"; \
	fi; \
	mkdir -p "$(DERIVED_DATA)"; \
	printf '%s\n' "$$root" > "$$marker"

build: prepare-local-caches
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

build-ci: prepare-local-caches
	@xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-sdk iphonesimulator \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGNING_ALLOWED=NO \
		build

build-release: prepare-local-caches
	@xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-sdk iphonesimulator \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGNING_ALLOWED=NO \
		build

run: build
	@test -n "$(SIMULATOR_TARGET)" || { echo "No available $(SIMULATOR_NAME) with iOS $(SIMULATOR_OS)" >&2; exit 2; }
	@xcrun simctl boot "$(SIMULATOR_TARGET)" >/dev/null 2>&1 || true
	@xcrun simctl bootstatus "$(SIMULATOR_TARGET)" -b
	@xcrun simctl install "$(SIMULATOR_TARGET)" "$(APP_PATH)"
	@xcrun simctl launch --terminate-running-process "$(SIMULATOR_TARGET)" "$(BUNDLE_ID)"

test-ui: prepare-local-caches
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

audit-project:
	@python3 scripts/audit-project.py

public-scan:
	@./scripts/public-scan.sh

check: build-ci audit-project verify-showcase public-scan

release-check: check build-release test-ui
