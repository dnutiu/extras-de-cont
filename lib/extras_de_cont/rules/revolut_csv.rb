# frozen_string_literal: true

require "bigdecimal"
require "csv"
require "date"
require "digest"

module ExtrasDeCont
  module Rules
    # Parses Revolut's account-statement CSV export.
    class RevolutCsv < Rules::Base
      REQUIRED_HEADERS = ["Started Date", "Description", "Amount", "Fee", "Currency", "State"].freeze
      INCLUDED_STATES = %w[COMPLETED REVERTED].freeze

      def parse(source)
        csv_data = source.respond_to?(:read) ? source.read : source.to_s
        csv_data = csv_data.dup.force_encoding(Encoding::UTF_8).delete_prefix("\uFEFF")
        rows = CSV.parse(csv_data, headers: true, skip_blanks: true)
        validate_headers!(rows.headers)

        rows.filter_map do |row|
          state = row["State"].to_s.strip.upcase
          next unless INCLUDED_STATES.include?(state)

          parse_row(row, state)
        end
      end

      private

      def validate_headers!(headers)
        missing_headers = REQUIRED_HEADERS - Array(headers)
        return if missing_headers.empty?

        raise ArgumentError, "Invalid Revolut CSV: missing #{missing_headers.join(", ")} column(s)"
      end

      def parse_row(row, state)
        date = DateTime.strptime(row.fetch("Started Date").to_s.strip, "%Y-%m-%d %H:%M:%S").to_date
        description = row.fetch("Description").to_s.strip
        currency = row.fetch("Currency").to_s.strip.upcase
        amount = decimal(row.fetch("Amount")) - decimal(row["Fee"], default: "0")
        amount = -amount if state == "REVERTED"

        raise ArgumentError, "Invalid Revolut CSV: included row has no description" if description.empty?
        return if amount.zero?

        Transaction.new(
          date,
          description,
          amount,
          currency,
          state: state,
          deduplication_key: deduplication_key(row, state)
        )
      rescue ArgumentError => e
        raise e if e.message.start_with?("Invalid Revolut CSV")

        raise ArgumentError, "Invalid Revolut CSV row: #{e.message}"
      end

      def decimal(value, default: nil)
        value = default if value.to_s.strip.empty? && !default.nil?
        BigDecimal(value.to_s.strip)
      end

      def deduplication_key(row, state)
        Digest::SHA256.hexdigest(
          [
            row["Type"],
            row["Product"],
            row["Started Date"],
            row["Completed Date"],
            row["Description"],
            row["Amount"],
            row["Fee"],
            row["Currency"],
            state
          ].map { |value| value.to_s.strip }.join("\u001f")
        )
      end
    end
  end
end
