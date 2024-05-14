TOOL = scripts/swift-run.sh
PACKAGE = swift package -c release --package-path Tools
SWIFT_FILE_PATHS = Package.swift Tools/Package.swift Sources Tests Examples

.PHONY: open-dev
open-dev:
	DEVELOPMENT=1 open Package.swift

.PHONY: proj
proj:
	SWIFT_PACKAGE_RESOURCES=Tools/.build/checkouts/XcodeGen/SettingPresets $(TOOL) xcodegen -s Examples/project.yml

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
	  --include-extended-types \
	  --experimental-skip-synthesized-symbols \
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
	  --include-extended-types \
	  --experimental-skip-synthesized-symbols \
	  --product Atoms
