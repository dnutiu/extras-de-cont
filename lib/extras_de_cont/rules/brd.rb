# frozen_string_literal: true

require "date"
require "extras_de_cont/transaction"

module ExtrasDeCont
  module Rules
    class Brd < Rules::Base
      DATE_PREFIX = /\A(?<date>\d{2}\/\d{2}\/\d{4})\b/
      AMOUNT_PATTERN = /\d{1,3}(?:\.\d{3})*,\d{2}/
      TABLE_HEADER_PATTERN = /Data oper\.\s+Descriere operatiune\s+Debit\s+Credit\s+Data val\./

      NOISE_PATTERNS = [
        /\APag\./,
        /\ABRD-Groupe/,
        /\ACAPITAL SOCIAL/,
        /\AMihalache/,
        /\ATel:/,
        /\ARO361579/,
        /\A255\/06/,
        /\APJR01INCR/,
        /\ACIFRE CHEIE/,
        /\ACONTURI DETINUTE/,
        /\AFonduri proprii/,
        /\ALimita de credit/,
        /\ACredit neutilizat/,
        /\ADescoperit/,
        /\ANr\. Zile/,
        /\ATotal disponibil/,
        /\ATotal sume/,
        /\ADomicilierea contului/,
        /\AReferinte bancare/,
        /\ATitular \/ Account/,
        /\AIBAN /,
        /\ANumar cont/,
        /\AExtras de cont/,
        /\ADe la \/ From/,
        /\ADocumentul este/,
        /\ACNP\/CUI:/,
        /\ASWIFT/,
        /\AAg\. /,
        /\AStr\. /,
        /\A•/,
        /\Ahttp/,
        /\ASold/,
        /\ATotal debit/,
        /\ACard:MBS/,
        /\ATrans\.Date/
      ].freeze

      def parse(text)
        transactions = []
        current_table = nil
        current_currency = nil
        above_lines = []
        below_lines = []
        date_line = nil

        each_normalized_line(text) do |line|
          if line.start_with?("Valuta / Currency")
            current_currency = line.split.last
            next
          end

          if table_header?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            current_table = extract_columns(line)
            above_lines = []
            below_lines = []
            date_line = nil
            next
          end

          if noise?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            above_lines = []
            below_lines = []
            date_line = nil
            next
          end

          next if current_table.nil?

          if date_line?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            date_line = line
            below_lines = []
            next
          end

          if date_line
            below_lines << line
          else
            above_lines << line
          end
        end

        try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
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

      def table_header?(line)
        line.match?(TABLE_HEADER_PATTERN)
      end

      def date_line?(line)
        line.match?(DATE_PREFIX)
      end

      def noise?(line)
        NOISE_PATTERNS.any? { |pattern| line.match?(pattern) }
      end

      def extract_columns(line)
        {
          debit: line.index("Debit"),
          credit: line.index("Credit")
        }
      end

      def try_flush(date_line, above_lines, below_lines, table, currency, transactions)
        return if date_line.nil? || table.nil?

        transaction = build_transaction(date_line, above_lines, below_lines, table, currency)
        transactions << transaction if transaction
      end

      def build_transaction(date_line, above_lines, below_lines, table, currency)
        date_match = date_line.match(DATE_PREFIX)
        return if date_match.nil?

        date = parse_date(date_match[:date])

        amounts_on_date = date_line.to_enum(:scan, AMOUNT_PATTERN).map { Regexp.last_match }

        if amounts_on_date.any?
          transaction_amount_match = amounts_on_date.first
          main_description = date_line[date_match.end(0)...transaction_amount_match.begin(0)].to_s.strip
        else
          amount_line = below_lines.find { |l| l.match?(AMOUNT_PATTERN) }
          return unless amount_line

          amount_match = amount_line.match(AMOUNT_PATTERN)
          transaction_amount_match = amount_match
          main_description = date_line[date_match.end(0)..].to_s.strip
          main_description = main_description.sub(/\s*\d{2}\/\d{2}\/\d{4}\s*\z/, "")
        end

        midpoint = (table[:debit] + 2 * table[:credit]) / 3
        debit = transaction_amount_match.begin(0) < midpoint
        amount = parse_amount(transaction_amount_match[0])
        amount = -amount if debit

        description_lines = below_lines.map(&:strip).reject(&:empty?)
        if !amounts_on_date.any? && description_lines.first
          stripped = description_lines.first.sub(AMOUNT_PATTERN, "").strip
          description_lines[0] = stripped unless stripped.empty?
        end
        description_parts = [*above_lines.map(&:strip), main_description, *description_lines]
        description = description_parts.reject(&:empty?).join(" | ")

        Transaction.new(date, description, amount, currency)
      end

      def parse_date(value)
        day, month, year = value.split("/").map(&:to_i)
        Date.new(year, month, day)
      end

      def parse_amount(value)
        value.delete(".").sub(",", ".").to_f
      end
    end
  end
end
