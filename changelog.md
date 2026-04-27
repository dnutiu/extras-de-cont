

# v1.1.0

- Extended support for parsing Revolut statements in multiple currencies.
- Extend parser to parse Revolut Business statements.

```ruby
CURRENCY_SYMBOLS = {
"$" => "USD",
"€" => "EUR",
"£" => "GBP",
"zł" => "PLN",
"Kč" => "CZK",
"Ft" => "HUF",
"лв" => "BGN",
"₺" => "TRY",
"₴" => "UAH"
}.freeze
```

# v1.0.0

- Initial commit
- Support for parsing Revolut statement in RON