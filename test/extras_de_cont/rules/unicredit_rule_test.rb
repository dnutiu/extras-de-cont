#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "extras_de_cont"

class UniCreditRuleTest < Minitest::Test
  class TestParser < ExtrasDeCont::Parser
    attr_reader :text

    def initialize(text)
      @text = text
      super
    end
  end

  EUR_SAMPLE = <<~TEXT
    TRANZACȚII

    Data                Descriere                                                   Debit               Credit                Sold(EUR)

                        +CMS CLT-1234567890
                        Card 5500-00XX-XXXX-1234

                        2026.01.15 SAMPLE STORE
    15 ianuarie 2026    LUX-LUXEMBOURG                                               12.50                                        1,000.00
                        Auth code 123456
                        12 50 EUR

                        CUMPARARE PRIN POS

                        +GPP 0987654321
                        SCT REF. 0987654321 EUR

    20 ianuarie 2026    500 00 Sample Sender Sent                                                             500.00                   1,500.00
                        from Sample Bank
                        REF1234567890

                        Plata electronica SEPA 1122334455
                        SCT REF. 1122334455 EUR

    25 ianuarie 2026    Sample Recipient Rent                                        300.00                                       1,200.00
                        Rent payment January
                        REF0987654321
  TEXT

  RON_SAMPLE = <<~TEXT
    TRANZACȚII

    Data                Descriere                                                 Debit              Credit               Sold(RON)

                        Incasare Instant in RON 00123456789
                        Sample Sender CONT

                        RO00BANK0000000000000000
                        LA SAMPLE BANK S.A.
    05 februarie 2026   SUCURSALA REF. client                                                            1,000.00                 2,000.00
                        Sent from Sample
                        INSTANT INTER NONREF

                        Plata electronica Instant interbancara in RON
                        00987654321
                        Sample Payee S.A.

    10 februarie 2026   LA SAMPLE BANK                                            200.00                                       1,800.00
                        REF. client
                        payment description

                        Transfer electronic Instant intre conturile proprii in RON
                        00555444333
                        SAMPLE OWNER CONT
    15 februarie 2026   LA SAMPLE BANK                                            500.00                                       1,300.00
                        INSTANT INTRA
  TEXT

  PAGE_BREAK_SAMPLE = <<~TEXT
    TRANZACȚII

    Data                Descriere                                                   Debit               Credit                Sold(EUR)

                        +CMS CLT-1111111111
                        Card 5500-00XX-XXXX-1234

                        2026.01.10 SAMPLE
    10 ianuarie 2026    STORE LUX-LUXEMBOURG                                        20.00                                        980.00
                        Auth code 111111

    UniCredit Bank S.A.
    Bulevardul Expoziției nr. 1F,
    unicredit.ro                                                                                                                      1/2

    TRANZACȚII

    Data                Descriere                                                   Debit               Credit                Sold(EUR)

                        +CMS CLT-2222222222
                        Card 5500-00XX-XXXX-1234

                        2026.01.11 SAMPLE2
    11 ianuarie 2026    STORE LUX-LUXEMBOURG                                        30.00                                        950.00
                        Auth code 222222

    Prezentul extras are valoare de original
    Fondurile disponibile
    Pentru mai multe detalii
  TEXT

  def test_parses_eur_transactions
    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(EUR_SAMPLE)

    assert_equal 3, transactions.size

    assert_equal Date.new(2026, 1, 15), transactions[0].date
    assert_equal(-12.50, transactions[0].amount)
    assert_equal "EUR", transactions[0].currency
    assert_includes transactions[0].description, "+CMS CLT-1234567890"
    assert_includes transactions[0].description, "LUX-LUXEMBOURG"
    assert_includes transactions[0].description, "CUMPARARE PRIN POS"

    assert_equal Date.new(2026, 1, 20), transactions[1].date
    assert_equal 500.0, transactions[1].amount
    assert_equal "EUR", transactions[1].currency
    assert_includes transactions[1].description, "Sample Sender"
    assert_includes transactions[1].description, "REF1234567890"

    assert_equal Date.new(2026, 1, 25), transactions[2].date
    assert_equal(-300.0, transactions[2].amount)
    assert_equal "EUR", transactions[2].currency
    assert_includes transactions[2].description, "Sample Recipient"
    assert_includes transactions[2].description, "Rent payment January"
  end

  def test_parses_ron_transactions
    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(RON_SAMPLE)

    assert_equal 3, transactions.size

    assert_equal Date.new(2026, 2, 5), transactions[0].date
    assert_equal 1000.0, transactions[0].amount
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "Incasare Instant"
    assert_includes transactions[0].description, "Sample Sender"

    assert_equal Date.new(2026, 2, 10), transactions[1].date
    assert_equal(-200.0, transactions[1].amount)
    assert_equal "RON", transactions[1].currency
    assert_includes transactions[1].description, "Plata electronica"

    assert_equal Date.new(2026, 2, 15), transactions[2].date
    assert_equal(-500.0, transactions[2].amount)
    assert_equal "RON", transactions[2].currency
    assert_includes transactions[2].description, "Transfer electronic"
    assert_includes transactions[2].description, "INSTANT INTRA"
  end

  def test_parses_all_romanian_months
    month_sample = (1..12).map do |m|
      month_name = ExtrasDeCont::Rules::UniCredit::ROMANIAN_MONTHS.key(m)
      <<~ENTRY
        TRANZACȚII
        Data                Descriere                                                   Debit               Credit                Sold(RON)
        #{m.to_s.rjust(2, "0")} #{month_name} 2026       Test #{month_name}                                           100.00                   200.00
      ENTRY
    end.join("\n")

    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(month_sample)

    assert_equal 12, transactions.size
    transactions.each_with_index do |t, i|
      assert_equal Date.new(2026, i + 1, (i + 1).to_s.rjust(2, "0").to_i), t.date
      assert_includes t.description, "Test #{ExtrasDeCont::Rules::UniCredit::ROMANIAN_MONTHS.key(i + 1)}"
    end
  end

  def test_detects_debit_and_credit_correctly
    mixed_sample = <<~TEXT
      TRANZACȚII
      Data                Descriere                                                   Debit               Credit                Sold(EUR)
      10 ianuarie 2026    Debit transaction                                            50.00                                        950.00
      11 ianuarie 2026    Credit transaction                                                                   100.00                 1,050.00
    TEXT

    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(mixed_sample)

    assert_equal 2, transactions.size
    assert_equal(-50.0, transactions[0].amount)
    assert_equal "EUR", transactions[0].currency
    assert_equal 100.0, transactions[1].amount
    assert_equal "EUR", transactions[1].currency
  end

  def test_handles_page_breaks
    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(PAGE_BREAK_SAMPLE)

    assert_equal 2, transactions.size

    assert_equal Date.new(2026, 1, 10), transactions[0].date
    assert_equal(-20.0, transactions[0].amount)
    assert_includes transactions[0].description, "STORE LUX-LUXEMBOURG"

    assert_equal Date.new(2026, 1, 11), transactions[1].date
    assert_equal(-30.0, transactions[1].amount)
    assert_includes transactions[1].description, "STORE LUX-LUXEMBOURG"
  end

  def test_parser_delegates_to_unicredit_rule
    parser = TestParser.new(EUR_SAMPLE)
    transactions = parser.parse_with(ExtrasDeCont::Rules::UniCredit.new)

    assert_equal 3, transactions.size
    assert_equal(-12.50, transactions.first.amount)
    assert_equal "EUR", transactions.first.currency
  end

  def test_top_level_parse_with_unicredit_bank
    transactions = ExtrasDeCont::Rules::UniCredit.new.parse(EUR_SAMPLE)

    assert_equal 3, transactions.size
    assert_equal "EUR", transactions.first.currency
  end
end
