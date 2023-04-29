TOOL = scripts/swift-run.sh
PACKAGE = SWIFTUI_ATOM_PROPERTIES_DEVELOPMENT=1 swift package -c release
SWIFT_FILE_PATHS = Package.swift Sources Tests Examples
TEST_PLATFORM_IOS = iOS Simulator,name=iPhone 13 Pro
TEST_PLATFORM_MACOS = macOS
TEST_PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (at 1080p) (2nd generation)
TEST_PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 7 (45mm)

.PHONY: proj
proj:
	SWIFT_PACKAGE_RESOURCES=.build/checkouts/XcodeGen/SettingPresets $(TOOL) xcodegen -s Examples/project.yml

.PHONY: format
format:
	$(TOOL) swift-format format -i -p -r $(SWIFT_FILE_PATHS)

.PHONY: lint
lint:
	$(TOOL) swift-format lint -s -p -r $(SWIFT_FILE_PATHS)

.PHONY: docs
docs:
	$(PACKAGE) \
	  --allow-writing-to-directory docs \
	  generate-documentation \
	  --product Atoms \
	  --disable-indexing \
	  --transform-for-static-hosting \
	  --hosting-base-path swiftui-atom-properties \
	  --output-path docs

.PHONY: docs-preview
docs-preview:
	$(PACKAGE) \
	  --disable-sandbox \
	  preview-documentation \
	  --product Atoms

.PHONY: test
test: test-library test-examples

.PHONY: test-library
test-library:
	for platform in "$(TEST_PLATFORM_IOS)" "$(TEST_PLATFORM_MACOS)" "$(TEST_PLATFORM_TVOS)" "$(TEST_PLATFORM_WATCHOS)"; do \
	    xcodebuild test -scheme swiftui-atom-properties -destination platform="$$platform"; \
	done

.PHONY: test-examples
test-examples:
	cd Examples/Packages/iOS && for platform in "$(TEST_PLATFORM_IOS)" ; do \
	    xcodebuild test -scheme iOSExamples -destination platform="$$platform"; \
	done
	cd Examples/Packages/CrossPlatform && for platform in "$(TEST_PLATFORM_IOS)" "$(TEST_PLATFORM_MACOS)" "$(TEST_PLATFORM_TVOS)" ; do \
	    xcodebuild test -scheme CrossPlatformExamples  -destination platform="$$platform"; \
	done
