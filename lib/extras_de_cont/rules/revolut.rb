# frozen_string_literal: true

require "date"
require "extras_de_cont/transaction"

module ExtrasDeCont
  module Rules
    # Rules for parsing Revolut bank statements.
    class Revolut < Rules::Base
      SECTION_HEADERS = [
        "Pending from ",
        "Account transactions from ",
        "Reverted from ",
        "Deposit transactions from "
      ].freeze

      DOCUMENT_NOISE_HEADERS = [
        "Balance summary",
        "The balance on your statement might differ",
        "Report lost or stolen card",
        "+",
        "Get help directly in app",
        "Scan the QR code",
        "RON Statement",
        "Generated on the ",
        "Revolut Bank UAB",
        "© "
      ].freeze

      DATE_PREFIX = /\A(?<date>[A-Z][a-z]{2} \d{1,2}, \d{4})\b/
      AMOUNT = /-?\d[\d,]*\.\d{2} [A-Z]{3}/

      def parse(text)
        transactions = []
        current_table = nil
        current_lines = []

        each_normalized_line(text) do |line|
          if table_header?(line)
            flush_transaction(current_lines, transactions, current_table)
            current_table = extract_table(line)
            next
          end

          if document_noise?(line)
            flush_transaction(current_lines, transactions, current_table)
            next
          end

          if section_header?(line)
            flush_transaction(current_lines, transactions, current_table)
            current_table = nil
            next
          end

          next if ignorable_line?(line)
          next if current_table.nil?

          if line.match?(DATE_PREFIX)
            flush_transaction(current_lines, transactions, current_table)
            current_lines = [line]
          elsif current_lines.any?
            current_lines << line
          end
        end

        flush_transaction(current_lines, transactions, current_table)
        transactions
      end

      private

      def each_normalized_line(text)
        text.each_line do |line|
          normalized_line = line.tr("\u00A0", " ").strip
          next if normalized_line.empty?

          yield normalized_line
        end
      end

      def flush_transaction(current_lines, transactions, current_table)
        return if current_lines.empty? || current_table.nil?

        transaction = build_transaction(current_lines, current_table)
        transactions << transaction if transaction
        current_lines.clear
      end

      def build_transaction(lines, table)
        row = lines.first
        metadata_lines = lines.drop(1)
        match = DATE_PREFIX.match(row)
        return if match.nil?

        description, amount_string, debit = extract_transaction_amount(row, match, table)
        return if amount_string.nil?

        description_parts = [description, *metadata_lines.map(&:strip)]
        description = description_parts.reject(&:empty?).join(" | ")
        amount = parse_amount(amount_string)
        amount = -amount if debit

        Transaction.new(
          parse_date(match[:date]),
          description,
          amount,
          amount_string.split.last
        )
      end

      def parse_date(value)
        Date.strptime(value, "%b %e, %Y")
      end

      def parse_amount(value)
        value.split.first.delete(",").to_f
      end

      def section_header?(line)
        SECTION_HEADERS.any? { |header| line.start_with?(header) }
      end

      def table_header?(line)
        line.start_with?("Date", "Start date") && line.include?("Description") && line.include?("Money out")
      end

      def ignorable_line?(line)
        line.start_with?("Money out", "Money in", "Balance")
      end

      def document_noise?(line)
        DOCUMENT_NOISE_HEADERS.any? { |header| line.start_with?(header) }
      end

      def extract_table(line)
        {
          money_out: line.index("Money out"),
          money_in: line.index("Money in"),
          balance: line.index("Balance"),
          has_balance: line.include?("Balance")
        }
      end

      def extract_transaction_amount(row, date_match, table)
        money_in_index = table.fetch(:money_in)
        amount_matches = row.to_enum(:scan, AMOUNT).map { Regexp.last_match }
        return if amount_matches.empty?

        transaction_match = if table.fetch(:has_balance)
                              amount_matches[-2] if amount_matches.length > 1
                            else
                              amount_matches[-1]
                            end
        return if transaction_match.nil?

        description = row[date_match.end(0)...transaction_match.begin(0)].to_s.strip
        amount_string = transaction_match[0]
        debit = transaction_match.begin(0) < money_in_index

        [description, amount_string, debit]
      end
    end
  end
end
