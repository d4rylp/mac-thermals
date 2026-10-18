# Mac Thermals developer commands. Requires Xcode 27.1, XcodeGen and SwiftLint
# (`brew install xcodegen swiftlint`).

PROJECT := MacThermals.xcodeproj
SCHEME := MacThermals
DESTINATION := platform=macOS,arch=arm64
BUILD_DIR := build
DERIVED_DATA := $(BUILD_DIR)/DerivedData
SOURCE_PACKAGES := $(BUILD_DIR)/SourcePackages
RESULT_BUNDLE := $(BUILD_DIR)/TestResults.xcresult
APP_NAME := Mac Thermals.app
INSTALL_DIR := /Applications
FORMAT_PATHS := App AppTests AppUITests Packages/ThermalKit/Package.swift Packages/ThermalKit/Sources Packages/ThermalKit/Tests

# Extra xcodebuild arguments, for example XCODEBUILD_FLAGS=CODE_SIGNING_ALLOWED=NO in CI.
XCODEBUILD_FLAGS ?=

XCODEBUILD := xcodebuild \
	-project $(PROJECT) \
	-scheme $(SCHEME) \
	-destination '$(DESTINATION)' \
	-derivedDataPath $(DERIVED_DATA) \
	-clonedSourcePackagesDirPath $(SOURCE_PACKAGES)

.PHONY: project build test lint format install clean hooks

project: ## Generate MacThermals.xcodeproj from project.yml
	xcodegen generate

build: project ## Build the app (Debug)
	$(XCODEBUILD) -configuration Debug $(XCODEBUILD_FLAGS) build

test: project ## Run the app tests and every ThermalKit test target
	rm -rf $(RESULT_BUNDLE)
	$(XCODEBUILD) -configuration Debug -resultBundlePath $(RESULT_BUNDLE) $(XCODEBUILD_FLAGS) test

lint: ## Check SwiftLint (strict) and swift-format
	swiftlint lint --strict --quiet
	swift format lint --strict --recursive --parallel $(FORMAT_PATHS)

format: ## Format all Swift sources in place
	swift format format --in-place --recursive --parallel $(FORMAT_PATHS)

install: project ## Build Release and copy the app to /Applications
	$(XCODEBUILD) -configuration Release $(XCODEBUILD_FLAGS) build
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	ditto "$(DERIVED_DATA)/Build/Products/Release/$(APP_NAME)" "$(INSTALL_DIR)/$(APP_NAME)"

clean: ## Remove build output and the generated project
	rm -rf $(BUILD_DIR) $(PROJECT)

hooks: ## Install the pre-commit hook that runs lint
	install -m 755 scripts/pre-commit "$$(git rev-parse --git-path hooks)/pre-commit"
