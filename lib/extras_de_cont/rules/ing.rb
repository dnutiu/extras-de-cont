# frozen_string_literal: true

require "date"
require "extras_de_cont/transaction"

module ExtrasDeCont
  module Rules
    class Ing < Rules::Base
      ROMANIAN_MONTHS = {
        "ianuarie" => 1, "februarie" => 2, "martie" => 3, "aprilie" => 4,
        "mai" => 5, "iunie" => 6, "iulie" => 7, "august" => 8,
        "septembrie" => 9, "octombrie" => 10, "noiembrie" => 11, "decembrie" => 12
      }.freeze

      RO_MONTH_NAMES = ROMANIAN_MONTHS.keys.freeze
      DATE_PATTERN = /\b(\d{1,2})\s+(#{RO_MONTH_NAMES.join("|")})\s+(\d{4})\b/i
      DATE_PREFIX = /\A\s*#{DATE_PATTERN}/

      TABLE_HEADER_PATTERN = /Data\s+Detalii tranzactie\s+Debit\s+Credit/

      AMOUNT_PATTERN = /\d{1,3}(?:\.\d{3})*,\d{2}/

      NOISE_PATTERNS = [
        /\AExtras de cont\z/,
        /\APentru perioada:/,
        /\AValabil fara semnatura/,
        /\AING Bank/,
        /\ASediul:/,
        /\ANr\. inregistrare/,
        /\ACIF:/,
        /\ATitular cont:/,
        /\ACNP:/,
        /\AStr\. /,
        /\ATip cont:/,
        /\ANumar cont:/,
        /\AMoneda:/,
        /\A\d{6},/,
        /\ARoxana Petria/,
        /\AAlexandra Ilie/,
        /\AȘef Serviciu/,
        /\ASef Serviciu/,
        /\ASucursala/,
        /\AÎN/,
        /\AInformatii despre/,
        /\Ape www\./,
        /\d+\/\d+$/
      ].freeze

      def parse(text)
        transactions = []
        current_currency = nil
        current_table = nil
        above_lines = []
        below_lines = []
        date_line = nil

        each_normalized_line(text) do |line|
          if line.start_with?("Moneda:")
            current_currency = line.split.last
            next
          end

          if table_header?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            current_table = extract_column_positions(line)
            above_lines, below_lines, date_line = [], [], nil
            next
          end

          if noise?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            above_lines, below_lines, date_line = [], [], nil
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

      def extract_column_positions(line)
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

        amounts = date_line.to_enum(:scan, AMOUNT_PATTERN).map { Regexp.last_match }
        return if amounts.empty?

        transaction_amount_match = amounts.last
        description_start = date_match.end(0)
        description_end = transaction_amount_match.begin(0)
        main_description = date_line[description_start...description_end].to_s.strip

        amount_string = transaction_amount_match[0]
        amount = parse_amount(amount_string)
        midpoint = (table[:debit] + table[:credit]) / 2
        amount = -amount if transaction_amount_match.begin(0) < midpoint

        description = build_description(main_description, above_lines, below_lines)

        Transaction.new(
          parse_date(date_match[1].to_i, date_match[2], date_match[3].to_i),
          description,
          amount,
          currency
        )
      end

      def parse_date(day, month_name, year)
        month = ROMANIAN_MONTHS[month_name.downcase]
        Date.new(year, month, day)
      end

      def parse_amount(value)
        value.delete(".").sub(",", ".").to_f
      end

      def build_description(main_desc, above_lines, below_lines)
        parts = [*above_lines.map(&:strip), main_desc, *below_lines.map(&:strip)]
        parts.reject(&:empty?).join(" | ")
      end
    end
  end
end
