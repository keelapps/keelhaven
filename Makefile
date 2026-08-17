# Thin task-runner over Scripts/ and the standard Swift/Xcode tooling.
# Logic lives in Scripts/*.sh (reusable by CI); this file is the command index.

.DEFAULT_GOAL := help

.PHONY: help bootstrap test restic build install update dev-site deploy-site clean

help: ## List available targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  make %-12s %s\n", $$1, $$2}'

bootstrap: ## Install development dependencies via Homebrew
	brew install restic xcodegen gh

test: ## Run KeelhavenCore tests (incl. the real-restic integration suite)
	swift test --package-path KeelhavenCore

restic: ## Vendor the universal restic binary that gets bundled into the app
	./Scripts/fetch-restic.sh

build: restic ## Build a Release Keelhaven.app from the working tree
	xcodegen generate
	xcodebuild -project Keelhaven.xcodeproj -scheme Keelhaven \
		-configuration Release -derivedDataPath build build

install: build ## Build from source and install to /Applications
	./Scripts/install-local.sh

update: ## Install the latest CI build from main (no local build)
	./Scripts/install-latest.sh

dev-site: ## Preview the website locally with live reload (serves under /keelhaven-site/)
	@[ -d site/node_modules ] || npm --prefix site install
	npm --prefix site run dev

deploy-site: ## Build site/ and push it to keelhaven-site's gh-pages (manual deploy)
	./Scripts/deploy-site.sh

clean: ## Remove generated project and build products
	rm -rf Keelhaven.xcodeproj build .build KeelhavenCore/.build
