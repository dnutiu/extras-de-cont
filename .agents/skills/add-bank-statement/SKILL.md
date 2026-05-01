---
name: add-bank-statement
description: Add support for a new bank statement PDF parser. Use when the user wants to integrate a new bank's PDF format into the extras_de_cont gem. Covers rule class creation, registration, RBS signatures, and tests.
---

## Purpose

Guide through adding a new bank statement parser to the `extras_de_cont` gem. Follow the existing conventions from `Revolut` and `UniCredit` rule classes.

## Process

### Step 1 — Gather Information

Ask the user for:
- **Bank identifier** — a short symbol used in `BANK_RULES` (e.g. `:ing`, `:brd`, `:bt`). Must be lowercase, snake_case.
- **PDF file path** — path to a sample bank statement PDF. Use `ruby -Ilib -e 'require "extras_de_cont"; puts ExtrasDeCont::Parser.new(ARGV[0]).text' /path/to/statement.pdf` to extract the raw text. This is critical for building the parser.
- **Currency** — what currency(ies) the statement uses, and how the currency code/symbol appears in the text.
- **Any special features** — page breaks, multi-section statements, balance columns, Romanian month names, business vs personal accounts, etc.

**Important:** Extracted PDF text will contain sensitive information (names, IBANs, card numbers, transaction IDs). The raw text must be anonymized before using it as a test fixture. Do not commit or expose the raw text anywhere.

### Step 2 — Create the Rule Class

Create `lib/extras_de_cont/rules/<bank>.rb` with this skeleton:

```ruby
# frozen_string_literal: true

require "date"
require "extras_de_cont/transaction"

module ExtrasDeCont
  module Rules
    class <BankName> < Rules::Base
      def parse(text)
        transactions = []
        # ... parsing logic ...
        transactions
      end

      private

      def each_normalized_line(text)
        text.each_line do |line|
          normalized = line.tr("\u00A0", " ").strip
          next if normalized.empty?
          yield normalized
        end
      end
    end
  end
end
```

Key conventions:
- Class name in `CamelCase` matching the bank (e.g. `Ing`, `Brd`, `Bt`).
- Inherit from `Rules::Base`.
- Include `# frozen_string_literal: true`.
- Require `date` and `extras_de_cont/transaction`.
- Implement `parse(text)` returning `Array<Transaction>`.
- Use `each_normalized_line` to iterate over non-empty lines (handles `\u00A0` non-breaking spaces).
- Define constants for patterns at the top of the class.
- Keep parsing methods private.

### Step 3 — Build the Parsing Logic

Most bank statements are table-based. Analyze the sample text to identify:

1. **Table headers** — lines containing column names like `Date`, `Description`, `Debit`, `Credit`, `Money out`, `Money in`, `Balance`, `Sold`. Know the column positions to determine debit vs credit.

2. **Date pattern** — how transaction dates appear (e.g. `Apr 3, 2026`, `dd month_ro yyyy`, `YYYY.MM.DD`). Build a `DATE_PREFIX` regex anchored to line start.

3. **Amount pattern** — currency symbol prefix/suffix, thousands separators, decimal separators. Build an `AMOUNT_PATTERN` regex.

4. **Debit/Credit detection** — use column index positions (like `table[:money_in]`) to decide if an amount is debit (negative) or credit (positive). For amounts left of the credit column midpoint, make negative.

5. **Section handling** — statements often have sections (pending, reverted, deposits). Use section header patterns to reset state.

6. **Noise filtering** — headers, footers, page numbers, legal text. Build `NOISE_PATTERNS` or `NOISE_HEADERS` lists.

7. **Multi-line descriptions** — lines after the date line that belong to the same transaction. Accumulate into `above_lines`/`below_lines`, join with ` | `.

Reference the existing rule classes for implementation patterns:
- `lib/extras_de_cont/rules/revolut.rb` — complex multi-section, multi-currency, symbol-based amounts.
- `lib/extras_de_cont/rules/unicredit.rb` — Romanian month names, page breaks, new-transaction markers (`+CMS`, `+GPP`).

### Step 4 — Register the Bank

Edit `lib/extras_de_cont.rb`:

1. Add `require "extras_de_cont/rules/<bank>"` at the top with the other requires.
2. Add `symbol: Rules::<BankName>` to the `BANK_RULES` hash (keep keys alphabetically sorted).

### Step 5 — Add RBS Signatures (Optional)

If adding types, create `sig/extras_de_cont/rules/<bank>.rbs`:

```rbs
module ExtrasDeCont
  module Rules
    class <BankName> < Rules::Base
      def parse: (String text) -> Array[Transaction]
    end
  end
end
```

### Step 6 — Write Tests

Create `test/extras_de_cont/rules/<bank>_rule_test.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "extras_de_cont"

class <BankName>RuleTest < Minitest::Test
  class TestParser < ExtrasDeCont::Parser
    attr_reader :text

    def initialize(text)
      @text = text
      super
    end
  end

  SAMPLE_STATEMENT = <<~TEXT
    # Paste anonymized sample text here — see rules below
  TEXT

  def test_parses_transactions
    transactions = ExtrasDeCont::Rules::<BankName>.new.parse(SAMPLE_STATEMENT)
    # Assert expected count, dates, amounts (sign), currencies, descriptions
  end

  def test_parser_delegates_to_rule
    parser = TestParser.new(SAMPLE_STATEMENT)
    transactions = parser.parse_with(ExtrasDeCont::Rules::<BankName>.new)
    # Assert delegation works
  end
end
```

Test structure conventions:
- Use a `TestParser` subclass that skips PDF reading by overriding `text`.
- Define sample statement as a heredoc constant using anonymized data.
- Test at minimum: transaction count, dates, amounts (sign), currencies, and key description parts.
- Test edge cases: page breaks, empty statements, debit/credit sign detection, multi-line descriptions.
- Test the delegation path via `Parser#parse_with`.

**Anonymization rules — never commit real financial data:**

- Replace real **names** with generic placeholders (e.g. `SAMPLE SENDER`, `Sample Recipient`).
- Replace real **IBANs** with fake ones (e.g. `RO00BANK0000111122223333`).
- Replace real **account numbers** with masked versions (e.g. `RO11REVO0000111122223333`).
- Replace real **card numbers** with masked patterns (e.g. `400000******1234`, `5500-00XX-XXXX-1234`).
- Replace real **transaction IDs / GUIDs** with fake UUIDs (e.g. `11111111-2222-4333-8444-555555555555`).
- Replace real **company names and addresses** with generic placeholders.
- Replace real **reference numbers** with fake ones (e.g. `REF1234567890`).
- Keep **amounts, dates, and currency values** intact — only replace identifying information.

Copy the anonymized text from the real PDF output, replace sensitive fields, and use the result as the test fixture. Refer to existing test files for examples of properly sanitized fixtures.

### Step 7 — Verify

Run the tests and lint:

```bash
bundle exec ruby -Ilib:test test/extras_de_cont/rules/<bank>_rule_test.rb
bundle exec rake standard
```

### Step 8 — Update README

Add the newly added bank to the `README.md` in the `Supported Banks` section.

### Checklist

- [ ] Rule class created in `lib/extras_de_cont/rules/<bank>.rb`
- [ ] Class inherits from `Rules::Base`, implements `parse(text)`
- [ ] Bank registered in `lib/extras_de_cont.rb` (`require` + `BANK_RULES`)
- [ ] Date parsing, amount parsing, debit/credit detection implemented
- [ ] Section headers and document noise filtered
- [ ] Multi-line transaction descriptions joined properly
- [ ] Test fixtures are anonymized — no real names, IBANs, card numbers, or transaction IDs
- [ ] Tests cover main scenarios and edge cases
- [ ] Tests pass and lint is clean
