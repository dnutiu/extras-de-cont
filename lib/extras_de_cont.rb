# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "unicredit" => "UniCredit"
)
loader.setup

# The ExtrasDeCont module contains utilities for parsing bank statements.
module ExtrasDeCont
  # Map of supported banks (symbol → rule class)
  BANK_RULES = {
    brd: ExtrasDeCont::Rules::Brd,
    ing: ExtrasDeCont::Rules::Ing,
    revolut: ExtrasDeCont::Rules::Revolut,
    revolut_csv: ExtrasDeCont::Rules::RevolutCsv,
    unicredit: ExtrasDeCont::Rules::UniCredit
  }.freeze

  RAW_TEXT_BANKS = %i[revolut_csv].freeze

  class << self
    # Parses a bank statement and returns structured transactions.
    #
    # @param file [String, Pathname, IO] path to the PDF file or an IO-like object
    # @param bank [Symbol] the bank identifier (:unicredit, :revolut, :revolut_csv, etc.)
    # @param exclude [Array<String, Transaction>] deduplication keys or transactions already imported
    # @return [Array<ExtrasDeCont::Transaction>]
    # @raise [ArgumentError] if the bank is not supported
    def parse(file, bank:, exclude: [])
      bank = bank.to_sym
      rule_class = BANK_RULES[bank]
      raise ArgumentError, "Unsupported bank: #{bank}. Supported banks: #{BANK_RULES.keys.join(", ")}" unless rule_class

      transactions =
        if RAW_TEXT_BANKS.include?(bank)
          rule_class.new.parse(read_raw_file(file))
        else
          ExtrasDeCont::Parser.new(file).parse_with(rule_class.new)
        end

      deduplicate(transactions, exclude, within_file: RAW_TEXT_BANKS.include?(bank))
    end

    private

    def read_raw_file(file)
      return file.read if file.respond_to?(:read)
      return file if file.is_a?(String) && !file_path?(file)

      File.binread(file.respond_to?(:to_path) ? file.to_path : file)
    end

    def file_path?(file)
      File.file?(file)
    rescue Errno::ENAMETOOLONG
      false
    end

    def deduplicate(transactions, exclude, within_file:)
      seen = Array(exclude).to_h do |item|
        [item.respond_to?(:deduplication_key) ? item.deduplication_key : item.to_s, true]
      end

      transactions.each_with_object([]) do |transaction, unique_transactions|
        key = transaction.deduplication_key
        next if seen.key?(key)

        unique_transactions << transaction
        seen[key] = true if within_file
      end
    end
  end
end

loader.eager_load
