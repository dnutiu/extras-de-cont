#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "extras_de_cont"

class RevolutRuleTest < Minitest::Test
  class TestParser < ExtrasDeCont::Parser
    attr_reader :text

    def initialize(text)
      @text = text
      super
    end
  end

  SAMPLE_STATEMENT = <<~TEXT
    Pending from April 1, 2026 to April 21, 2026

    Start date           Description                                           Money out            Money in

    Apr 21, 2026         Glovo                                                 125.55 RON
                         Transaction Id: 11111111-2222-4333-8444-555555555555
                         Card: 400000******1234, Bucuresti

    Account transactions from April 1, 2026 to April 21, 2026

    Date                 Description                                           Money out            Money in                    Balance

    Apr 3, 2026          Apple Pay top-up by *5461                                                           1,000.00 RON              1,561.95 RON
                         RO11REVO0000111122223333-aaaa-bbbb-cccc-dddddddddddd
                         From: *5461

               Report lost or stolen card    Revolut Bank UAB is authorised by the Bank of Lithuania in the Republic of Lithuania and by the European Central Bank. Registered
               +40800476135                  address: Konstitucijos ave. 21B, Vilnius, 08130, the Republic of Lithuania
    © 2026 Revolut Bank UAB Vilnius Sucursala București                                                                                      Page 2 of 6                                                                                                           RON Statement
                                                                                                                     Generated on the Apr 21, 2026
                                                                                                      Revolut Bank UAB Vilnius Sucursala București

    Date                    Description                                                 Money out               Money in                        Balance

    Apr 7, 2026          Claude.ai                                             111.92 RON                                         905.76 RON
                         Transaction Id: 66666666-7777-4888-9999-aaaaaaaaaaaa
                         Revolut Rate 1.00 RON = €0.19 (ECB rate* 1.00 RON = €0.20)  €21.78
                         To: Claude.ai Subscription, Anthropic.com, CA
                         Card: 400000******1234

    Reverted from April 1, 2026 to April 21, 2026

    Start date             Description                                               Money out              Money in

    Apr 9, 2026            Glovo                                                     2.00 RON
                          Transaction Id: bbbbbbbb-cccc-4ddd-8eee-ffffffffffff
                          To: Glovoglovo Prime, None
                          Card: 400000******1234

    Deposit transactions from April 1, 2026 to April 21, 2026

    Date                   Description                                               Money out              Money in                      Balance

    Apr 1, 2026            Net Interest Paid to 'Savings Account' for Apr 1, 2026                           1.11 RON               15,001.11 RON
                          Transaction Id: 12345678-90ab-4cde-8f01-234567890abc

    Apr 6, 2026            From RON Savings Account                                  15,006.66 RON                                      0.00 RON
                          Transaction Id: fedcba98-7654-4321-8abc-def012345678
                          RO11REVO0000111122223333
  TEXT

  def test_parses_revolut_statement_sections
    transactions = ExtrasDeCont::Rules::Revolut.new.parse(SAMPLE_STATEMENT)

    assert_equal 6, transactions.size

    assert_equal Date.new(2026, 4, 21), transactions[0].date
    assert_equal(-125.55, transactions[0].amount)
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "Glovo"
    assert_includes transactions[0].description, "Transaction Id:"

    assert_equal Date.new(2026, 4, 3), transactions[1].date
    assert_equal 1000.0, transactions[1].amount
    assert_includes transactions[1].description, "Apple Pay top-up by *5461"
    assert_includes transactions[1].description, "From: *5461"

    assert_equal Date.new(2026, 4, 7), transactions[2].date
    assert_equal(-111.92, transactions[2].amount)
    assert_includes transactions[2].description, "Claude.ai Subscription"

    assert_equal Date.new(2026, 4, 9), transactions[3].date
    assert_equal(-2.0, transactions[3].amount)
    assert_includes transactions[3].description, "Glovoglovo Prime"

    assert_equal Date.new(2026, 4, 1), transactions[4].date
    assert_equal 1.11, transactions[4].amount
    assert_includes transactions[4].description, "Savings Account"

    assert_equal Date.new(2026, 4, 6), transactions[5].date
    assert_equal(-15_006.66, transactions[5].amount)
    assert_includes transactions[5].description, "From RON Savings Account"
  end

  def test_parser_delegates_to_revolut_rule
    parser = TestParser.new(SAMPLE_STATEMENT)
    transactions = parser.parse_with(ExtrasDeCont::Rules::Revolut.new)

    assert_equal 6, transactions.size
    assert_equal(-15_006.66, transactions.last.amount)
  end

  def test_parses_extracted_pdf_text_when_available
    pdf_text_path = File.expand_path("../pdf_text.txt", __dir__)
    skip "pdf_text.txt is not available" unless File.exist?(pdf_text_path)

    transactions = ExtrasDeCont::Rules::Revolut.new.parse(File.read(pdf_text_path))

    assert_equal 75, transactions.size
    assert_equal(-125.55, transactions.first.amount)
    assert_equal "RON", transactions.first.currency

    account_credit = transactions.find do |transaction|
      transaction.description.include?("Apple Pay top-up") && transaction.amount.between?(999.99, 1000.01)
    end
    assert account_credit

    exchange_debit = transactions.find { |transaction| transaction.description.include?("Exchanged to USD") }
    assert_equal(-15_000.0, exchange_debit.amount)

    deposit_credit = transactions.find { |transaction| transaction.description.include?("Savings Account' for Apr 1") }
    assert_equal 1.11, deposit_credit.amount

    deposit_debit = transactions.find do |transaction|
      transaction.description.start_with?("From RON Savings Account") && transaction.amount.negative?
    end
    assert_equal(-15_006.66, deposit_debit.amount)
  end

  def test_parses_revolut_pdf_when_available
    pdf_path = File.expand_path("../tranzactii_revolut.pdf", __dir__)
    skip "tranzactii_revolut.pdf is not available" unless File.exist?(pdf_path)

    transactions = ExtrasDeCont.parse(pdf_path, bank: :revolut)

    assert_equal 75, transactions.size
    assert_equal(-125.55, transactions.first.amount)
    assert_equal(-15_006.66, transactions.last.amount)
  end
end
