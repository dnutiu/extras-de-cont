# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "extras_de_cont"
  s.version = "1.0.1"
  s.licenses = ["GPLv3"]
  s.summary = "A simple library which helps you extract transactions from a PDF bank statement."
  s.description = <<~TEXT
    A simple library which helps you extract transactions from a PDF bank statement.
    Fine tuned for Romanian bank statements.

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
      puts "\#{t.date}, \#{t.description}, \#{t.amount}, \#{t.currency}"
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

  TEXT
  s.authors = ["Denis Nutiu"]
  s.email = "dnutiu@nuculabs.dev"
  s.homepage = "https://nuculabs.dev"
  s.metadata = { "source_code_uri" => "https://gitlab.nuculabs.dev/dnutiu/extras-de-cont",
                 "rubygems_mfa_required" => "true" }
  s.required_ruby_version = ">= 3.0.0"

  # Files to include in the gem
  s.files = Dir["{lib, sig}/**/*", "LICENSE", "README.md", "extras_de_cont.gemspec"]

  # Optional but recommended
  s.require_paths = ["lib"]

  s.add_dependency "pdf-reader", "~> 2.15"
end
