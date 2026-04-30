# frozen_string_literal: true

require "date"
require "extras_de_cont/transaction"

module ExtrasDeCont
  module Rules
    class UniCredit < Rules::Base
      ROMANIAN_MONTHS = {
        "ianuarie" => 1, "februarie" => 2, "martie" => 3, "aprilie" => 4,
        "mai" => 5, "iunie" => 6, "iulie" => 7, "august" => 8,
        "septembrie" => 9, "octombrie" => 10, "noiembrie" => 11, "decembrie" => 12
      }.freeze

      RO_MONTH_NAMES = ROMANIAN_MONTHS.keys.freeze
      DATE_PATTERN = /\b(\d{1,2})\s+(#{RO_MONTH_NAMES.join("|")})\s+(\d{4})\b/i
      DATE_PREFIX = /\A\s*#{DATE_PATTERN}/

      TABLE_HEADER_PATTERN = /Data\s+Descriere\s+Debit\s+Credit\s+Sold/

      SECTION_HEADERS = [
        "TRANZACȚII",
        "SUMAR CONT",
        "EXTRAS DE CONT"
      ].freeze

      NOISE_PATTERNS = [
        /\AUniCredit Bank S\.A\./,
        /\ABulevardul/,
        /\ASector \d/,
        /\ATel:/,
        /\AEmail:/,
        /\Aunicredit\.ro/,
        /\ACapital social:/,
        /\APrezentul extras/,
        /\AFondurile disponibile/,
        /\APentru mai multe/,
        /\ANUME CLIENT:/,
        /\AADRESA:/,
        /\ASUCURSALA:/,
        /\ADATA EXTRAS CONT/,
        /\APERIOADA/,
        /\ATIP CONT:/,
        /\AIBAN:/,
        /\AMONEDA:/,
        /\AOperator de date/,
        /\ASold inițial/,
        /\ASold ﬁnal/,
        /\AOperator de date cu/
      ].freeze

      NEW_TRANSACTION_MARKERS = [
        /\A\+CMS CLT-/,
        /\A\+GPP/,
        /\APlata electronica/,
        /\APlata Instant/,
        /\AIncasare Instant/,
        /\ATransfer electronic/
      ].freeze

      AMOUNT_PATTERN = /\d{1,3}(?:[.,]\d{3})*\.\d{2}/
      CURRENCY_FROM_HEADER = /Sold\(([A-Z]{3})\)/

      def parse(text)
        transactions = []
        current_currency = nil
        current_table = nil
        above_lines = []
        below_lines = []
        date_line = nil

        each_normalized_line(text) do |line|
          if (m = line.match(CURRENCY_FROM_HEADER))
            current_currency = m[1]
          end

          if table_header?(line)
            try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
            current_table = extract_column_positions(line)
            above_lines, below_lines, date_line = [], [], nil
            next
          end

          if noise?(line) || section_header?(line)
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
            if new_transaction_marker?(line)
              try_flush(date_line, above_lines, below_lines, current_table, current_currency, transactions)
              date_line, below_lines = nil, []
              above_lines = [line]
            else
              below_lines << line
            end
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

      def section_header?(line)
        SECTION_HEADERS.any? { |header| line == header }
      end

      def new_transaction_marker?(line)
        NEW_TRANSACTION_MARKERS.any? { |pattern| line.match?(pattern) }
      end

      def extract_column_positions(line)
        {
          debit: line.index("Debit"),
          credit: line.index("Credit"),
          sold: line.index("Sold")
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
        return if amounts.size < 2

        transaction_amount_match = amounts[-2]
        description_start = date_match.end(0)
        description_end = transaction_amount_match.begin(0)
        main_description = date_line[description_start...description_end].to_s.strip

        amount_string = transaction_amount_match[0]
        amount = amount_string.delete(", ").to_f
        midpoint = (table[:debit] + table[:credit]) / 2
        amount = -amount if transaction_amount_match.begin(0) < midpoint

        description = build_description(main_description, above_lines, below_lines)

        Transaction.new(
          parse_date(date_match[1].to_i, date_match[2], date_match[3].to_i),
          description,
          amount,
          currency || extract_currency_from_header(date_line)
        )
      end

      def parse_date(day, month_name, year)
        month = ROMANIAN_MONTHS[month_name.downcase]
        Date.new(year, month, day)
      end

      def build_description(main_desc, above_lines, below_lines)
        parts = [*above_lines.map(&:strip), main_desc, *below_lines.map(&:strip)]
        parts.reject(&:empty?).join(" | ")
      end

      def extract_currency_from_header(date_line)
        m = date_line.match(CURRENCY_FROM_HEADER)
        m ? m[1] : nil
      end
    end
  end
end
