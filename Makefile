# Todos — convenience targets
#
# WHY THE FILTER:
#   The SwiftBuild backend incorrectly computes framework search paths as
#   <CLT>/Developer/… when Xcode.app is absent, producing two benign "search
#   path not found" linker warnings. All frameworks resolve correctly; the
#   warnings are noise. The filter removes only those two specific lines.
#
# DEVELOPER_DIR is kept explicit for the same reason — it makes SwiftBuild
# compute the primary compiler paths correctly.

DEVELOPER_DIR := /Library/Developer/CommandLineTools
export DEVELOPER_DIR

# Filter out the known-benign CLT linker path warnings from swift build output.
SWIFT_BUILD_FILTER := grep -v "search path '.*CommandLineTools/Developer.*/.*' not found" || true

.PHONY: build run release clean lint lint-fix gitleaks hooks

## Build debug binary (warnings filtered)
build:
	swift build 2>&1 | $(SWIFT_BUILD_FILTER)

## Build and launch the menubar app
run:
	swift build 2>&1 | $(SWIFT_BUILD_FILTER)
	.build/debug/Todos

## Build optimised release binary (warnings filtered)
release:
	swift build -c release 2>&1 | $(SWIFT_BUILD_FILTER)

## Remove all build artefacts
clean:
	rm -rf .build Todos.app

## Run SwiftLint (report only)
lint:
	DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/usr/lib \
	  swiftlint lint --config .swiftlint.yml

## Run SwiftLint and auto-correct fixable violations
lint-fix:
	DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/usr/lib \
	  swiftlint lint --fix --config .swiftlint.yml

## Scan for secrets with gitleaks
gitleaks:
	gitleaks detect --config .gitleaks.toml --source .

## Install pre-commit hooks into .git/hooks/
hooks:
	pre-commit install
	@echo "pre-commit hooks installed. They will run on every git commit."
