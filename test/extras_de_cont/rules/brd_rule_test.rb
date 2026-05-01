#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "extras_de_cont"

class BrdRuleTest < Minitest::Test
  class TestParser < ExtrasDeCont::Parser
    attr_reader :text

    def initialize(text)
      @text = text
      super
    end
  end

  RON_SAMPLE = <<~TEXT
    Valuta / Currency         RON

    Data oper.              Descriere operatiune           Debit                         Credit         Data val.
    Trans.Date             Transaction description                                                     Value date

                          Sold initial / Start balance                                            959,21

    14/04/2026     Incasare din schimb valutar                                                        2.528,50 14/04/2026
                   Mobile Omnichannel
                   CSVMOCA000000000000
                   SAMPLE ACCOUNT HOLDER
                   RO00BRDE000SV00000000001
                   Vinz. valuta EUR curs: 5.0570000

    15/04/2026     Transfer credit - Plata interb.                  622,98                                     15/04/2026
                   OP00
                   SAMPLE COMPANY SRL
                   RO00INGB0000000000000000

    15/04/2026     Comision operatiune                               24,00                                     15/04/2026
                   Ghiseu
                   SAMPLE ACCOUNT HOLDER

    27/04/2026     Comis de administrarea contului                   24,00                                     27/04/2026
                   Automat
                   NC 0000000000000000

    30/04/2026     Comision Administrare Pachet                      20,00                                     30/04/2026
                   Automat
                   NC 0000000000000001
                   SAMPLE ACCOUNT HOLDER

                  Card:MBS        Nr 400000******1234           Posesor: Dl SAMPLE HOLDER

    10/04/2026      Utilizare POS comerciant alte BC                  763,82                                       08/04/2026
                    Card/Terminale OP 0000000/00000 Card nr....1234
                    OMV 0000 Sample ROM

    22/04/2026                                                                                                     19/04/2026
                    Utilizare POS comerciant alte BC                  403,10
                    Card/Terminale OP 0000000/00001 Card nr....1234
                    SAMPLE Station Sample ROM
  TEXT

  EUR_SAMPLE = <<~TEXT
    Valuta / Currency         EUR

    Data oper.              Descriere operatiune           Debit                         Credit         Data val.
    Trans.Date             Transaction description                                                     Value date

                          Sold initial / Start balance                                          5.964,42

    01/09/2025     Retrageri de numerar-ATM UEinEUR                   500,00                                   30/08/2025
                   Card/Terminale
                   OP 0000000/00000
                   Card nr....0000
                   SAMPLE BANK EG SAMPLE DEU

    01/09/2025     ComUtil ATM/MBA retragere num.                      5,49                                  30/08/2025
                   Card/Terminale
                   OP 0000000/00000
                   Card nr....0000
                   27.86RON-BNR 5.0722 RON/EUR

    01/09/2025     Utilizare POS comerciant strain.                   99,98                                  30/08/2025
                   Card/Terminale
                   OP 0000000/00001
                   Card nr....0000
                   SAMPLE STORE SAMPLE CITY AUT

    18/09/2025     Transfer credit - Inc. externa                                                             5.500,00 18/09/2025
                   Automat
                   SAMPLE GMBH
                   /DE00000000000000000000
                   Sample Str. 00000 SampleCity
                   SAMPLE BANK
  TEXT

  AMOUNT_ON_BELOW_LINE_SAMPLE = <<~TEXT
    Valuta / Currency         RON

    Data oper.              Descriere operatiune           Debit                         Credit         Data val.
    Trans.Date             Transaction description                                                     Value date

                          Sold initial / Start balance                                            959,21

    22/04/2026                                                                                                     19/04/2026
                Utilizare POS comerciant alte BC                  403,10
                Card/Terminale OP 0000000/00001 Card nr....1234
  TEXT

  def test_parses_ron_transactions
    transactions = ExtrasDeCont::Rules::Brd.new.parse(RON_SAMPLE)

    assert_equal 7, transactions.size

    assert_equal Date.new(2026, 4, 14), transactions[0].date
    assert_equal 2528.50, transactions[0].amount
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "Incasare din schimb valutar"
    assert_includes transactions[0].description, "Mobile Omnichannel"
    assert_includes transactions[0].description, "CSVMOCA000000000000"

    assert_equal Date.new(2026, 4, 15), transactions[1].date
    assert_equal(-622.98, transactions[1].amount)
    assert_equal "RON", transactions[1].currency
    assert_includes transactions[1].description, "Transfer credit"
    assert_includes transactions[1].description, "SAMPLE COMPANY SRL"

    assert_equal Date.new(2026, 4, 15), transactions[2].date
    assert_equal(-24.0, transactions[2].amount)
    assert_equal "RON", transactions[2].currency
    assert_includes transactions[2].description, "Comision operatiune"

    assert_equal Date.new(2026, 4, 27), transactions[3].date
    assert_equal(-24.0, transactions[3].amount)
    assert_equal "RON", transactions[3].currency
    assert_includes transactions[3].description, "Comis de administrarea contului"

    assert_equal Date.new(2026, 4, 30), transactions[4].date
    assert_equal(-20.0, transactions[4].amount)
    assert_equal "RON", transactions[4].currency
    assert_includes transactions[4].description, "Comision Administrare Pachet"

    assert_equal Date.new(2026, 4, 10), transactions[5].date
    assert_equal(-763.82, transactions[5].amount)
    assert_equal "RON", transactions[5].currency
    assert_includes transactions[5].description, "Utilizare POS"
    assert_includes transactions[5].description, "Card/Terminale"

    assert_equal Date.new(2026, 4, 22), transactions[6].date
    assert_equal(-403.10, transactions[6].amount)
    assert_equal "RON", transactions[6].currency
    assert_includes transactions[6].description, "Utilizare POS"
    assert_includes transactions[6].description, "SAMPLE Station"
  end

  def test_parses_eur_transactions
    transactions = ExtrasDeCont::Rules::Brd.new.parse(EUR_SAMPLE)

    assert_equal 4, transactions.size

    assert_equal Date.new(2025, 9, 1), transactions[0].date
    assert_equal(-500.0, transactions[0].amount)
    assert_equal "EUR", transactions[0].currency
    assert_includes transactions[0].description, "Retrageri de numerar-ATM"

    assert_equal Date.new(2025, 9, 1), transactions[1].date
    assert_equal(-5.49, transactions[1].amount)
    assert_equal "EUR", transactions[1].currency
    assert_includes transactions[1].description, "ComUtil ATM"

    assert_equal Date.new(2025, 9, 1), transactions[2].date
    assert_equal(-99.98, transactions[2].amount)
    assert_equal "EUR", transactions[2].currency
    assert_includes transactions[2].description, "Utilizare POS comerciant strain"

    assert_equal Date.new(2025, 9, 18), transactions[3].date
    assert_equal 5500.0, transactions[3].amount
    assert_equal "EUR", transactions[3].currency
    assert_includes transactions[3].description, "Transfer credit"
    assert_includes transactions[3].description, "SAMPLE GMBH"
  end

  def test_handles_amount_on_below_line
    transactions = ExtrasDeCont::Rules::Brd.new.parse(AMOUNT_ON_BELOW_LINE_SAMPLE)

    assert_equal 1, transactions.size
    assert_equal Date.new(2026, 4, 22), transactions[0].date
    assert_equal(-403.10, transactions[0].amount)
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "Utilizare POS"
  end

  def test_detects_debit_and_credit_correctly
    sample = <<~TEXT
      Valuta / Currency         RON

      Data oper.              Descriere operatiune           Debit                         Credit         Data val.
      Trans.Date             Transaction description                                                     Value date

                            Sold initial / Start balance                                          1.000,00

      10/04/2026     Debit transaction                                50,00                                     10/04/2026
      11/04/2026     Credit transaction                                                                   100,00 11/04/2026
    TEXT

    transactions = ExtrasDeCont::Rules::Brd.new.parse(sample)

    assert_equal 2, transactions.size
    assert_equal(-50.0, transactions[0].amount)
    assert_equal "RON", transactions[0].currency
    assert_equal 100.0, transactions[1].amount
    assert_equal "RON", transactions[1].currency
  end

  def test_parser_delegates_to_brd_rule
    parser = TestParser.new(RON_SAMPLE)
    transactions = parser.parse_with(ExtrasDeCont::Rules::Brd.new)

    assert_equal 7, transactions.size
    assert_equal "RON", transactions.first.currency
  end

  def test_empty_statement
    sample = <<~TEXT
      Valuta / Currency         RON

      Data oper.              Descriere operatiune           Debit                         Credit         Data val.
      Trans.Date             Transaction description                                                     Value date

                            Sold initial / Start balance                                          1.000,00
    TEXT

    transactions = ExtrasDeCont::Rules::Brd.new.parse(sample)
    assert_equal 0, transactions.size
  end

  def test_handles_multiline_descriptions
    sample = <<~TEXT
      Valuta / Currency         RON

      Data oper.              Descriere operatiune           Debit                         Credit         Data val.
      Trans.Date             Transaction description                                                     Value date

                            Sold initial / Start balance                                          1.000,00

      10/04/2026     Plata factura                                   100,00                                   10/04/2026
                      Factura nr. 1234
                      SAMPLE PROVIDER SRL
                      RO00BRDE000SV00000000001
    TEXT

    transactions = ExtrasDeCont::Rules::Brd.new.parse(sample)

    assert_equal 1, transactions.size
    assert_includes transactions[0].description, "Plata factura"
    assert_includes transactions[0].description, "Factura nr. 1234"
    assert_includes transactions[0].description, "SAMPLE PROVIDER SRL"
    assert_includes transactions[0].description, "RO00BRDE000SV00000000001"
  end
end
