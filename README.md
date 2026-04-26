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

Or use the included entrypoint:

```bash
bundle exec ruby -Ilib bin/main /home/dnutiu/Documents/tranzactii_revolut.pdf
```

Run the Revolut parser test with:

```bash
ruby -Ilib:test test/revolut_rule_test.rb
```
