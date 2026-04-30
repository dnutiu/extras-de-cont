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

  EUR_SAMPLE_STATEMENT = <<~TEXT
    EUR Statement

    Generated on the Apr 26, 2026

    Balance summary

    Product                                                 Opening balance       Money out             Money in                    Closing balance
    Account (Current Account)                               €0.00                 €15,400.00            €15,400.00                  €0.00

    Account transactions from April 1, 2026 to April 26, 2026

    Date                  Description                                             Money out             Money in                     Balance

    Apr 15, 2026          Transfer from SAMPLE SENDER                                                   €400.00                      €400.00
                          Reference: Chirie aprilie
                          Transaction Id: 11111111-2222-4333-8444-555555555555
                          From: SAMPLE SENDER, RO11REVO0000111122223333

    Apr 15, 2026          Apple Pay top-up by *0537                                                     €5,000.00                  €5,400.00
                          RO11REVO0000111122223333-aaaa-bbbb-cccc-dddddddddddd
                          From: *0537

    Apr 15, 2026          To investment account                                   €5,097.47                                          €302.53
                          Transaction Id: 22222222-3333-4444-8555-666666666666
                          RO11REVO0000111122223333

    Apr 15, 2026          Exchanged to RON                                        €302.53                                              €0.00
                          Transaction Id: 33333333-4444-4555-8666-777777777777
                                                                                  1,532.46 RON

    Apr 20, 2026          Apple Pay top-up by *0537                                                     €5,000.00                  €5,000.00
                          Transaction Id: 44444444-5555-4666-8777-888888888888
                          From: *0537

    Apr 20, 2026          To investment account                                   €5,000.00                                            €0.00
                          RO11REVO0000111122223333-eeee-ffff-aaaa-bbbbbbbbbbbb

    Apr 23, 2026          Top Up                                                                        €5,000.00                  €5,000.00
                          Reference: From investment account
                          Transaction Id: 55555555-6666-4777-8888-999999999999
                          RO11REVO0000111122223333

    Report lost or stolen card  address: Konstitucijos ave. 21B, Vilnius, 08130, the Republic of Lithuania
    © 2026 Revolut Bank UAB Vilnius Sucursala București                                                                            Page 1 of 2                                                                                                                EUR Statement

    Generated on the Apr 26, 2026

    Revolut Bank UAB Vilnius Sucursala București

    Date                    Description                                                   Money out                Money in                        Balance

    Apr 23, 2026            To Sample Beneficiary                                          €5,000.00                                                  €0.00
                            Reference: Sent from Revolut
                            Transaction Id: 66666666-7777-4888-8999-aaaaaaaaaaaa
                            RO11REVO0000111122223333
                            To: Sample Beneficiary, RO22BANK0000111122223333
  TEXT

  SYMBOL_CURRENCY_SAMPLE_STATEMENT = <<~TEXT
    Account transactions from April 1, 2026 to April 26, 2026

    Date                  Description                                             Money out             Money in                     Balance

    Apr 10, 2026          USD card payment                                        $12.34                                             $87.66
                          Transaction Id: 77777777-8888-4999-8aaa-bbbbbbbbbbbb

    Apr 11, 2026          GBP transfer                                                                  £45.67                      £45.67
                          Transaction Id: 88888888-9999-4aaa-8bbb-cccccccccccc

    Apr 12, 2026          PLN cash withdrawal                                     20.00 zł                                           25.67 zł
                          Transaction Id: 99999999-aaaa-4bbb-8ccc-dddddddddddd

    Apr 13, 2026          CZK top-up                                                                    1,234.56 Kč                 1,260.23 Kč
                          Transaction Id: aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee

    Apr 14, 2026          HUF transfer                                            500.00 Ft                                          760.23 Ft
                          Transaction Id: bbbbbbbb-cccc-4ddd-8eee-ffffffffffff

    Apr 15, 2026          BGN transfer                                                                  30.00 лв                   790.23 лв
                          Transaction Id: cccccccc-dddd-4eee-8fff-111111111111

    Apr 16, 2026          TRY payment                                             ₺10.00                                            ₺780.23
                          Transaction Id: dddddddd-eeee-4fff-8111-222222222222

    Apr 17, 2026          UAH top-up                                                                    ₴25.00                     ₴805.23
                          Transaction Id: eeeeeeee-ffff-4111-8222-333333333333
  TEXT

  BUSINESS_SAMPLE_STATEMENT = <<~TEXT
    Account statement

    Generated on the April 1, 2026

    SAMPLE BUSINESS LTD

    Balance summary

    Opening balance                                    €0.00
    Money in                                           €0.00
    Money out                                          €0.00
    Closing balance                                    €0.00

    Your funds are held and protected by a licensed bank.

    Transactions from March 1, 2026 to March 31, 2026

    Date (UTC)                        Description                                      Money out                   Money in                Balance

                                                       There were no transactions during this period

    Transaction types

    Card payments (CAR)                     Money sent (MOS)                 Money received (MOR)                  Money added (MOA)
    €0.00                                   €0.00                            €0.00                                 €0.00

    Transactions from March 1, 2026 to March 31, 2026

    Date (UTC)                         Description                                       Money out             Money in              Balance

    25 Mar 2026          MOS           To SAMPLE ACCOUNTANT - EXPERT                     388.41 RON                                470.61 RON
                                       Accounting services according to contract
                                       193/12.11.2025 - February 2026
                                       ID: 11111111-2222-4333-8444-555555555555
                                       To account: RO00BANK0000111122223333

    10 Mar 2026          FEE           Revolut Business Fee - Basic plan fee              50.00 RON                                859.02 RON
                                       ID: 22222222-3333-4444-8555-666666666666

    Transaction types

    Card payments (CAR)                   Money sent (MOS)                Money received (MOR)                Money added (MOA)
    0.00 RON                              - 388.41 RON                    0.00 RON                            0.00 RON

    Transactions from March 1, 2026 to March 31, 2026

    Date (UTC)                          Description                                          Money out              Money in               Balance

    31 Mar 2026           MOS           To SAMPLE OWNER - Transfer to personal                 $1 100.00                                    $200.00
                                        account
                                        ID: 33333333-4444-4555-8666-777777777777

    31 Mar 2026           MOA           Money added from SAMPLE CLIENT LLP -                                         $1 000.00            $1 200.00
                                        AGREEMENT NO SAMPLE-2026 FROM
                                        25.11.2025
                                        ID: 44444444-5555-4666-8777-888888888888
                                        From account: CY00000000000000000000000000
                                        To account: RO00REVO0000111122223333

    2 Mar 2026            MOS           To SAMPLE OWNER - Transfer to personal                 $1 000.00                                      $0.00
                                        account
                                        ID: 55555555-6666-4777-8888-999999999999

    2 Mar 2026            MOA           Money added from SAMPLE CLIENT LLP -                                         $1 000.00            $200.00
                                        AGREEMENT NO SAMPLE-2026 FROM
                                        25.11.2025
                                        ID: 66666666-7777-4888-8999-aaaaaaaaaaaa
                                        From account: CY00000000000000000000000000
                                        To account: RO00REVO0000111122223333

    Report lost or stolen card
    © 2026 Revolut Bank UAB Vilnius Sucursala București
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

  def test_parses_revolut_eur_statement
    transactions = ExtrasDeCont::Rules::Revolut.new.parse(EUR_SAMPLE_STATEMENT)

    assert_equal 8, transactions.size

    assert_equal Date.new(2026, 4, 15), transactions[0].date
    assert_equal 400.0, transactions[0].amount
    assert_equal "EUR", transactions[0].currency
    assert_includes transactions[0].description, "Transfer from SAMPLE SENDER"
    assert_includes transactions[0].description, "Reference: Chirie aprilie"

    assert_equal(-5097.47, transactions[2].amount)
    assert_equal "EUR", transactions[2].currency
    assert_includes transactions[2].description, "To investment account"

    assert_equal(-302.53, transactions[3].amount)
    assert_equal "EUR", transactions[3].currency
    assert_includes transactions[3].description, "1,532.46 RON"

    assert_equal Date.new(2026, 4, 23), transactions[7].date
    assert_equal(-5000.0, transactions[7].amount)
    assert_equal "EUR", transactions[7].currency
    assert_includes transactions[7].description, "Reference: Sent from Revolut"
  end

  def test_parses_common_currency_symbols
    transactions = ExtrasDeCont::Rules::Revolut.new.parse(SYMBOL_CURRENCY_SAMPLE_STATEMENT)

    assert_equal 8, transactions.size
    assert_equal(-12.34, transactions[0].amount)
    assert_equal "USD", transactions[0].currency
    assert_equal 45.67, transactions[1].amount
    assert_equal "GBP", transactions[1].currency
    assert_equal(-20.0, transactions[2].amount)
    assert_equal "PLN", transactions[2].currency
    assert_equal 1234.56, transactions[3].amount
    assert_equal "CZK", transactions[3].currency
    assert_equal(-500.0, transactions[4].amount)
    assert_equal "HUF", transactions[4].currency
    assert_equal 30.0, transactions[5].amount
    assert_equal "BGN", transactions[5].currency
    assert_equal(-10.0, transactions[6].amount)
    assert_equal "TRY", transactions[6].currency
    assert_equal 25.0, transactions[7].amount
    assert_equal "UAH", transactions[7].currency
  end

  def test_parses_revolut_business_statement
    transactions = ExtrasDeCont::Rules::Revolut.new.parse(BUSINESS_SAMPLE_STATEMENT)

    assert_equal 6, transactions.size

    assert_equal Date.new(2026, 3, 25), transactions[0].date
    assert_equal(-388.41, transactions[0].amount)
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "MOS"
    assert_includes transactions[0].description, "Accounting services"

    assert_equal Date.new(2026, 3, 10), transactions[1].date
    assert_equal(-50.0, transactions[1].amount)
    assert_equal "RON", transactions[1].currency
    assert_includes transactions[1].description, "Basic plan fee"

    assert_equal Date.new(2026, 3, 31), transactions[2].date
    assert_equal(-1100.0, transactions[2].amount)
    assert_equal "USD", transactions[2].currency
    assert_includes transactions[2].description, "Transfer to personal"

    assert_equal Date.new(2026, 3, 31), transactions[3].date
    assert_equal 1000.0, transactions[3].amount
    assert_equal "USD", transactions[3].currency
    assert_includes transactions[3].description, "AGREEMENT NO SAMPLE-2026"

    assert_equal(-1000.0, transactions[4].amount)
    assert_equal "USD", transactions[4].currency
    assert_equal 1000.0, transactions[5].amount
    assert_equal "USD", transactions[5].currency
  end

  def test_parser_delegates_to_revolut_rule
    parser = TestParser.new(SAMPLE_STATEMENT)
    transactions = parser.parse_with(ExtrasDeCont::Rules::Revolut.new)

    assert_equal 6, transactions.size
    assert_equal(-15_006.66, transactions.last.amount)
  end
end
