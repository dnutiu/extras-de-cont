# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "stringio"
require "extras_de_cont"

class RevolutCsvRuleTest < Minitest::Test
  CSV_STATEMENT = <<~CSV
    Type,Product,Started Date,Completed Date,Description,Amount,Fee,Currency,State,Balance
    Card Payment,Current,2026-04-09 18:20:44,,Glovo,-2.00,0.00,RON,REVERTED,
    Transfer,Current,2026-04-09 19:33:18,2026-04-10 20:02:57,Bolt,-13.60,0.00,RON,COMPLETED,658.63
    Interest,Deposit,2026-04-10 06:00:00,2026-04-10 06:00:00,"Net interest, Savings Account",0.76,0.07,RON,COMPLETED,659.32
    Transfer,Current,2026-04-11 10:00:00,2026-04-11 10:00:00,Duplicate,-13.60,0.00,RON,COMPLETED,645.72
    Transfer,Current,2026-04-11 10:00:00,2026-04-11 10:00:00,Duplicate,-13.60,0.00,RON,COMPLETED,632.12
    Card Payment,Current,2026-04-11 11:00:00,,Pending,-4.00,0.00,RON,PENDING,
  CSV

  def test_parses_completed_and_reverted_rows
    transactions = ExtrasDeCont.parse(StringIO.new(CSV_STATEMENT), bank: :revolut_csv)

    assert_equal 4, transactions.length
    assert_equal Date.new(2026, 4, 9), transactions.first.date
    assert_equal 2.0, transactions.first.amount.to_f
    assert transactions.first.reverted?
    assert_equal(-13.60, transactions[1].amount.to_f)
    assert_equal "Net interest, Savings Account", transactions[2].description
    assert_equal 0.69, transactions[2].amount.to_f
  end

  def test_excludes_transactions_by_deduplication_key
    all_transactions = ExtrasDeCont.parse(CSV_STATEMENT, bank: :revolut_csv)
    excluded_key = all_transactions[1].deduplication_key

    transactions = ExtrasDeCont.parse(CSV_STATEMENT, bank: :revolut_csv, exclude: [excluded_key])

    assert_equal 3, transactions.length
    refute(transactions.any? { |transaction| transaction.deduplication_key == excluded_key })
  end

  def test_accepts_transactions_as_exclusions
    transactions = ExtrasDeCont.parse(CSV_STATEMENT, bank: :revolut_csv)

    remaining = ExtrasDeCont.parse(CSV_STATEMENT, bank: :revolut_csv, exclude: [transactions.first])

    assert_equal 3, remaining.length
    refute remaining.any?(&:reverted?)
  end

  def test_rejects_csv_without_required_headers
    error = assert_raises(ArgumentError) do
      ExtrasDeCont.parse("Date,Description\n2026-04-09,Test\n", bank: :revolut_csv)
    end

    assert_includes error.message, "missing Started Date"
  end

  def test_supports_utf8_bom
    transactions = ExtrasDeCont.parse("\uFEFF#{CSV_STATEMENT}", bank: :revolut_csv)

    assert_equal 4, transactions.length
  end
end
