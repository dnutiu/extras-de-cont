# frozen_string_literal: true

require "extras_de_cont/parser"
require "extras_de_cont/rules/base"
require "extras_de_cont/rules/brd"
require "extras_de_cont/rules/ing"
require "extras_de_cont/rules/revolut"
require "extras_de_cont/rules/unicredit"

# The ExtrasDeCont module contains utilities for parsing bank statements.
module ExtrasDeCont
  # Map of supported banks (symbol → rule class)
  BANK_RULES = {
    brd: Rules::Brd,
    ing: Rules::Ing,
    revolut: Rules::Revolut,
    unicredit: Rules::UniCredit
  }.freeze

  class << self
    # Parses a PDF bank statement and returns structured transactions.
    #
    # @param file [String, Pathname, IO] path to the PDF file or an IO-like object
    # @param bank [Symbol] the bank identifier (:unicredit, :revolut, etc.)
    # @return [Array<ExtrasDeCont::Transaction>]
    # @raise [ArgumentError] if the bank is not supported
    def parse(file, bank:)
      rule_class = BANK_RULES[bank]
      raise ArgumentError, "Unsupported bank: #{bank}. Supported banks: #{BANK_RULES.keys.join(", ")}" unless rule_class

      p = Parser.new(file)
      p.parse_with(rule_class.new)
    end
  end
end
