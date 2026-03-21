# RB.Game — Build & Development Automation
# Usage: make <target>

.PHONY: help install lint format format-fix rojo rojo-obby test validate compliance godot-compliance launch-readiness pre-push check clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# --------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------

install: ## Install toolchain via Aftman
	aftman install

# --------------------------------------------------------------------------
# Linting & Formatting
# --------------------------------------------------------------------------

lint: ## Lint all Luau source with Selene
	selene roblox/src/ roblox/tests/
	selene roblox/obby/src/

format: ## Check Luau formatting (no changes)
	stylua --check roblox/src/ roblox/tests/
	stylua --check roblox/obby/src/

format-fix: ## Auto-format all Luau files
	stylua roblox/src/ roblox/tests/
	stylua roblox/obby/src/

# --------------------------------------------------------------------------
# Rojo
# --------------------------------------------------------------------------

rojo: ## Serve main Alchemy Academy project
	cd roblox && rojo serve default.project.json

rojo-obby: ## Serve Obby project
	cd roblox/obby && rojo serve default.project.json

rojo-build: ## Build main project to .rbxl (for CI or headless testing)
	cd roblox && rojo build default.project.json -o build.rbxl

# --------------------------------------------------------------------------
# Testing
# --------------------------------------------------------------------------

test: ## Run in-Studio tests (manual — see instructions)
	@echo "In-Studio tests run inside Roblox Studio."
	@echo "1. rojo serve (or: make rojo)"
	@echo "2. Open Studio, connect to Rojo"
	@echo "3. Place TestRunner.server.luau in ServerScriptService"
	@echo "4. Click Run → check Output window"
	@echo ""
	@echo "Test modules: EconomyTests, RecipeTests, SeasonalTests,"
	@echo "  NetworkTests, StringsTests, JournalTests, DataIntegrityTests"

validate: ## Run CI data integrity checks locally
	bash scripts/validate-data-integrity.sh

compliance: ## Run Roblox legal & compliance checks locally
	bash scripts/validate-compliance.sh

godot-compliance: ## Run Godot compliance checks locally
	bash scripts/validate-godot-compliance.sh

launch-readiness: ## Run launch readiness tracker locally
	bash scripts/validate-launch-readiness.sh

pre-push: ## Run fast pre-push safety checks
	bash scripts/pre-push-check.sh

check: lint format validate compliance godot-compliance launch-readiness ## Run all CI checks locally

# --------------------------------------------------------------------------
# Housekeeping
# --------------------------------------------------------------------------

clean: ## Remove build artifacts
	rm -f roblox/build.rbxl roblox/.sourcemap.json
	rm -f roblox/obby/.sourcemap.json
