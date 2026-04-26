# Repository Guidelines

## Project Structure & Module Organization

This repository is a Ruby gem for extracting transactions from PDF bank statements.

- `lib/extras_de_cont.rb` is the public gem entrypoint.
- `lib/extras_de_cont/parser.rb` handles PDF text extraction and rule delegation.
- `lib/extras_de_cont/rules/` contains bank-specific parsing rules, such as `revolut.rb` and `unicredit.rb`.
- `lib/extras_de_cont/transaction.rb` defines the transaction model returned by parsers.
- `sig/` contains RBS type signatures that should be kept aligned with public Ruby APIs.
- `test/` contains Minitest tests.
- `bin/example.rb` is a local runnable example.

Avoid committing real bank statements or sensitive extracted data. Use sanitized fixtures for tests.

## Build, Test, and Development Commands

- `bundle install` installs gem and development dependencies.
- `ruby -Ilib:test test/revolut_rule_test.rb` runs the Revolut parser tests without Bundler.
- `bundle exec ruby -Ilib:test test/revolut_rule_test.rb` runs tests using the bundle.
- `bundle exec rake standard` runs Standard Ruby lint checks.
- `bundle exec rake build` builds the gem into `pkg/`.
- `ruby -Ilib bin/example.rb path/to/statement.pdf` runs a local parsing example when applicable.

There is no default `rake` task, so call the desired task explicitly.

## Coding Style & Naming Conventions

Use Standard Ruby style via `standardrb`; do not hand-format against a different convention. Use two-space indentation, `snake_case` for methods and variables, `CamelCase` for classes/modules, and frozen string literals in Ruby files.

Keep rule classes under `ExtrasDeCont::Rules`, named after the bank, for example `ExtrasDeCont::Rules::Revolut`.

## Testing Guidelines

Tests use Minitest. Name test files with the `_test.rb` suffix and test methods with `test_...`.

Add focused tests for each parser behavior: section detection, debit/credit sign handling, multiline descriptions, page headers/footers, and balance-column handling. When using PDF-derived fixtures, sanitize transaction IDs, card numbers, account numbers, names, and addresses.

## Commit & Pull Request Guidelines

Existing history uses short imperative commit messages, including Conventional Commit style such as `feat: implement parser and transaction with types`. Prefer concise messages like `fix: parse Revolut page breaks` or `test: cover deposit transactions`.

Pull requests should include a short summary, test commands run, and any parsing assumptions or fixture changes. Link related issues when available. For parser changes, include before/after transaction counts when a PDF fixture is involved.

## Agent-Specific Instructions

Do not revert unrelated user changes. Keep parsing changes scoped to the relevant bank rule and update RBS signatures when public interfaces change. Never add unsanitized financial documents or extracted personal data to committed fixtures.
