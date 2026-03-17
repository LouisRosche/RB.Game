# Alchemy Academy — Test Suite

## Overview

This directory contains automated tests for the shared Luau modules in
`roblox/src/shared/`. These modules contain pure-function logic (data tables,
lookup helpers, value calculations) that can be validated without interacting
with Roblox services.

## What Is Testable

| Layer | Testable Here? | Examples |
|-------|---------------|----------|
| Shared data modules | Yes | `Recipes`, `Ingredients`, `Config`, `Cosmetics`, `GamePasses`, `SeasonalContent` |
| Pure helper functions | Yes | `Recipes.lookup()`, `Recipes.calculateValue()`, `GamePasses.hasPass()` |
| Server services | No (manual) | `GrowthService`, `MonetizationService` — depend on Roblox APIs |
| Client UI | No (manual) | `ShopPanel`, `JournalUI` — depend on PlayerGui and input |
| Physics / streaming | No (manual) | Part counts, StreamingEnabled behaviour |

## How to Run Tests in Roblox Studio

1. Open the place file in Roblox Studio.
2. In the Explorer, locate **ServerScriptService**.
3. Insert a new **Script** (server script) and paste the contents of
   `TestRunner.server.luau` into it.
4. Place each test ModuleScript (`RecipeTests`, `EconomyTests`,
   `SeasonalTests`) as children of the runner script, or anywhere under
   `ServerScriptService` — the runner discovers them by name suffix `Tests`.
5. Click **Run** (server-only) or **Play** (full client+server).
6. Open the **Output** window. The runner prints a colour-coded summary:
   - Green lines = passing tests
   - Red lines = failing tests
   - A final tally of pass / fail / total

### Alternative: TestService

Roblox's built-in **TestService** can also run scripts:

1. Move `TestRunner.server.luau` into a Script under `TestService`.
2. In the menu bar choose **Test > Run** (or the TestService play button).
3. Output appears in the same Output window.

## Test Naming Conventions

- Test **module files** are named `<Feature>Tests.luau` (PascalCase, plural).
- Each module returns a table of test functions.
- Test **function keys** use `snake_case` and start with `test_`:
  ```
  test_lookup_returns_correct_recipe
  test_unknown_combo_returns_nil
  ```
- Assertion helpers (`assertEqual`, `assertTrue`, `assertNil`) are provided by
  the test runner and passed into each test function via a context table.

## Adding New Tests

1. Create a new ModuleScript named `<Feature>Tests.luau`.
2. Return a table of `function(t)` entries where `t` provides assertion helpers.
3. The runner auto-discovers any ModuleScript whose name ends with `Tests`.
