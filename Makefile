TOOL = scripts/swift-run.sh
PACKAGE = SWIFTUI_ATOM_PROPERTIES_DEVELOPMENT=1 swift package -c release
SWIFT_FILE_PATHS = Package.swift Sources Tests Examples

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
