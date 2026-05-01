#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "extras_de_cont"

file = ARGV[0]

if file.nil? || file.strip.empty?
  warn "Usage: bundle exec ruby -Ilib bin/main /path/to/statement.pdf"
  exit 1
end

# puts ExtrasDeCont::Parser.new(file).text

transactions = ExtrasDeCont.parse(file, bank: :revolut)

transactions.each do |t|
  puts "#{t.date}, #{t.description}, #{t.amount}, #{t.currency}"
end