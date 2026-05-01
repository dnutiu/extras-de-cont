# ExtrasDeCont

A ruby gem for extracting bank statements from PDFs.

## Simple usage

Create a PDF parser and print the extracted text:

```ruby
require "bundler/setup"
require "extras_de_cont"

parser = ExtrasDeCont::Parser.new("/home/dnutiu/Documents/tranzactii_revolut.pdf")
puts parser.text
```

Or, extract all the transactions from a Revolut Bank statement PDF:

```ruby
transactions = ExtrasDeCont.parse(file, bank: :revolut)

transactions.each do |t|
  puts "#{t.date}, #{t.description}, #{t.amount}, #{t.currency}"
end
```

Or use the included entrypoint:

```bash
bundle exec ruby -Ilib bin/main /home/dnutiu/Documents/tranzactii_revolut.pdf
```

Run the Revolut parser test with:

```bash
ruby -Ilib:test test/revolut_rule_test.rb
```

## Supported Banks

| Bank | Symbol | Currencies | Features |
|---|---|---|---|
| Revolut | `:revolut` | RON, EUR, USD, GBP, PLN, CZK, HUF, BGN, TRY, UAH | Personal & Business, multi-section, symbol currencies |
| UniCredit | `:unicredit` | RON, EUR | Romanian month names, page breaks, transaction markers |
| BRD | `:brd` | RON, EUR | Below-line amounts, Romanian number format |

## Development

```bash
bundle install          # Install dependencies
bundle exec rake test   # Run all tests
bundle exec rake standard  # Run linter
bundle exec rake build  # Build gem
```

## Contributing

Contributions are welcome. Here is how to add a new bank:

### 1. Gather information

Obtain a sample PDF statement from the bank and extract its text:

```bash
ruby -Ilib -e 'require "extras_de_cont"; puts ExtrasDeCont::Parser.new(ARGV[0]).text' /path/to/statement.pdf
```

### 2. Create a rule class

Add `lib/extras_de_cont/rules/<bank>.rb` inheriting from `Rules::Base`. See existing rules in `lib/extras_de_cont/rules/` for patterns.

### 3. Register the bank

Add the require and `BANK_RULES` entry in `lib/extras_de_cont.rb`:

```ruby
require "extras_de_cont/rules/<bank>"
# ...
BANK_RULES = {
  brd: Rules::Brd,
  <bank>: Rules::<BankName>,
  revolut: Rules::Revolut,
  unicredit: Rules::UniCredit
}.freeze
```

### 4. Write tests

Add `test/extras_de_cont/rules/<bank>_rule_test.rb`. Use sanitized fixtures — never commit real financial data. Run with:

```bash
bundle exec ruby -Ilib:test test/extras_de_cont/rules/<bank>_rule_test.rb
bundle exec rake standard
```

### Code style

This project uses [Standard Ruby](https://github.com/standardrb/standard). Run `bundle exec rake standard` before submitting changes.

## AI-Assisted Development

This project supports AI-assisted development via [OpenCode](https://github.com/anomalyco/opencode).

A skill is provided for adding new bank statement parsers. When using an AI coding assistant, it can load the skill 
at `.agents/skills/add-bank-statement/SKILL.md` to guide the process. 
The skill covers rule class creation, registration, RBS signatures, test patterns, and fixture anonymization.

The project maintains a [MemPalace](https://github.com/anomalyco/mempalace) knowledge graph (`mempalace.yaml`) 
that organizes the codebase into wings and rooms. AI agents can query this to learn about the project structure, 
existing parsers, test patterns, and conventions without reading every file.

For more context, see `AGENTS.md`.
