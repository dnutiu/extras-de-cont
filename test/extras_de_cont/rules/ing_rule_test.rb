#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "extras_de_cont"

class IngRuleTest < Minitest::Test
  class TestParser < ExtrasDeCont::Parser
    attr_reader :text

    def initialize(text)
      @text = text
      super
    end
  end

  SAMPLE_STATEMENT = <<~TEXT
                                                                                                                              Extras de cont
    
                                                                                                        Pentru perioada: 01/01/2025-20/01/2025
    
                                                                                                               Valabil fara semnatura si stampila
    
    
    ING Bank N.V. Amsterdam - Sucursala Bucureşti
    Sediul: Str. Aviator Popisteanu, nr. 54A, Sector 1, Bucuresti, cod postal 012095;
    
    Nr. inregistrare in Registrul Institutiilor de Credit: RB-PJS-40 024/18.02.99; BIC(SWIFT): INGBROBU
    
    CIF: RO 6151100 Tel.: + 40 21 222 16 00; Fax: + 40 21 222 14 01
    
    Titular cont: DL Sample User                                                     Tip cont:        Cont Curent
    
    CNP: 0000000000000                                                                Numar cont:      RO83INGB0000999900000000
    Str. Sample, Nr. 18, Ap. 2
                                                                                      Moneda:          RON
    
    307395, Sample - Sat, Timis, RO
    
    
    
    
    Data                        Detalii tranzactie                                                                   Debit            Credit
    
    
    
    01 ianuarie 2025            Cumparare POS                                                                         89,50
                                Data finalizarii(decontarii): 01.01.2025
    
                                Numar card:xxxx xxxx xxxx 0000
                                Terminal:SAMPLE STORE 3026 RESITA 1 INT RO RESITA
                                Data autorizarii:30-12-2024
    
                                Numar autorizare:612138
    02 ianuarie 2025            Cumparare POS                                                                        259,31
    
                                Data finalizarii(decontarii): 02.01.2025
                                Numar card:xxxx xxxx xxxx 0000
                                Terminal:SAMPLE SHOP 0239 RO Sample
    
                                Data autorizarii:31-12-2024
                                Numar autorizare:510405
    
    02 ianuarie 2025            Tranzactie Round Up                                                                     1,00
                                Data finalizarii(decontarii): 02.01.2025
    
                                Referinta:14035
                                In contul:RO00INGB0000999900000000
                                Detalii:Suma tranzactiei: 89 RON
    
                                Platita la: SAMPLE MERCHANT
    02 ianuarie 2025            Transfer Home'Bank                                                                   240,00
    
                                Data finalizarii(decontarii): 02.01.2025
                                Beneficiar:Sample Beneficiary
                                In contul:RO00INGB0000999900000000
    
                                Catre:0000000000
                                Referinta:000000000
    
    03 ianuarie 2025            Tranzactie Round Up                                                                     5,00
                                Data finalizarii(decontarii): 03.01.2025
                                Referinta:14039
    
                                In contul:RO00INGB0000999900000000
                                Detalii:Suma tranzactiei: 50 RON
                                Platita la: SAMPLE COMPANY SRL
    
    
    
    
    
    Roxana Petria                                                                                        Alexandra Ilie
    
    
    Şef Serviciu Dezvoltare Produse                                                                      Şef Serviciu Relaţii Clienţi
     ING Bank N.V. Amsterdam                                                                             ING Bank N.V. Amsterdam
     Sucursala Bucureşti                                                                                 Sucursala Bucureşti
    
    
    
                                                                                                                                   1/12
    Informatii despre schema de garantare a depozitelor si tipurile de conturi eligibile sunt disponibile
    pe www.ing.ro/dgs si in locatiile bancii
  TEXT

  DEBIT_CREDIT_SAMPLE = <<~TEXT
    ING Bank N.V. Amsterdam - Sucursala Bucureşti
    
    Titular cont: DL Sample User                                                     Tip cont:        Cont Curent
                                                                                      Moneda:          RON
    
    
    
    Data                        Detalii tranzactie                                                                   Debit            Credit
    
    
    
    05 ianuarie 2025            Plata factura                                                                       100,00
                                Referinta:REF001
    
    06 ianuarie 2025            Incasare                                                                                                200,00
                                Referinta:REF002
  TEXT

  PAGE_BREAK_SAMPLE = <<~TEXT
    ING Bank N.V. Amsterdam - Sucursala Bucureşti
    
    Titular cont: DL Sample User
                                                                                      Moneda:          RON
    
    Data                        Detalii tranzactie                                                                   Debit            Credit
    
    10 ianuarie 2025            Plata online                                                                         50,00
                                Referinta:REF010
    
                                                                                                                                   1/2
    Informatii despre schema de garantare
    
    ING Bank N.V. Amsterdam - Sucursala Bucureşti
    
    Data                        Detalii tranzactie                                                                   Debit            Credit
    
    11 ianuarie 2025            Plata card                                                                         150,00
                                Referinta:REF011
  TEXT

  def test_parses_transactions
    transactions = ExtrasDeCont::Rules::Ing.new.parse(SAMPLE_STATEMENT)

    assert_equal 5, transactions.size

    assert_equal Date.new(2025, 1, 1), transactions[0].date
    assert_equal(-89.50, transactions[0].amount)
    assert_equal "RON", transactions[0].currency
    assert_includes transactions[0].description, "Cumparare POS"
    assert_includes transactions[0].description, "SAMPLE STORE"
    assert_includes transactions[0].description, "Numar autorizare:612138"

    assert_equal Date.new(2025, 1, 2), transactions[1].date
    assert_equal(-259.31, transactions[1].amount)
    assert_equal "RON", transactions[1].currency
    assert_includes transactions[1].description, "Cumparare POS"
    assert_includes transactions[1].description, "SAMPLE SHOP"

    assert_equal Date.new(2025, 1, 2), transactions[2].date
    assert_equal(-1.0, transactions[2].amount)
    assert_equal "RON", transactions[2].currency
    assert_includes transactions[2].description, "Tranzactie Round Up"
    assert_includes transactions[2].description, "SAMPLE MERCHANT"

    assert_equal Date.new(2025, 1, 2), transactions[3].date
    assert_equal(-240.0, transactions[3].amount)
    assert_equal "RON", transactions[3].currency
    assert_includes transactions[3].description, "Transfer Home'Bank"
    assert_includes transactions[3].description, "Sample Beneficiary"

    assert_equal Date.new(2025, 1, 3), transactions[4].date
    assert_equal(-5.0, transactions[4].amount)
    assert_equal "RON", transactions[4].currency
    assert_includes transactions[4].description, "Tranzactie Round Up"
    assert_includes transactions[4].description, "SAMPLE COMPANY SRL"
  end

  def test_detects_debit_and_credit_correctly
    transactions = ExtrasDeCont::Rules::Ing.new.parse(DEBIT_CREDIT_SAMPLE)

    assert_equal 2, transactions.size

    assert_includes transactions[0].description, "Plata factura"
    assert_equal(-100.0, transactions[0].amount)
    assert_equal "RON", transactions[0].currency

    assert_includes transactions[1].description, "Incasare"
    assert_equal 200.0, transactions[1].amount
    assert_equal "RON", transactions[1].currency
  end

  def test_handles_page_breaks
    transactions = ExtrasDeCont::Rules::Ing.new.parse(PAGE_BREAK_SAMPLE)

    assert_equal 2, transactions.size

    assert_equal Date.new(2025, 1, 10), transactions[0].date
    assert_equal(-50.0, transactions[0].amount)
    assert_includes transactions[0].description, "Plata online"

    assert_equal Date.new(2025, 1, 11), transactions[1].date
    assert_equal(-150.0, transactions[1].amount)
    assert_includes transactions[1].description, "Plata card"
  end

  def test_parses_all_romanian_months
    month_sample = (1..12).map do |m|
      month_name = ExtrasDeCont::Rules::Ing::ROMANIAN_MONTHS.key(m)
      <<~ENTRY
        ING Bank N.V. Amsterdam - Sucursala Bucureşti
        Moneda:          RON
        Data                        Detalii tranzactie                                                                   Debit            Credit
        #{m.to_s.rjust(2, "0")} #{month_name} 2026       Test #{month_name}                                            10,00
        Referinta:REF00
      ENTRY
    end.join("\n")

    transactions = ExtrasDeCont::Rules::Ing.new.parse(month_sample)

    assert_equal 12, transactions.size
    transactions.each_with_index do |t, i|
      assert_equal Date.new(2026, i + 1, (i + 1).to_s.rjust(2, "0").to_i), t.date
      assert_includes t.description, "Test #{ExtrasDeCont::Rules::Ing::ROMANIAN_MONTHS.key(i + 1)}"
      assert_equal(-10.0, t.amount)
      assert_equal "RON", t.currency
    end
  end

  def test_parser_delegates_to_ing_rule
    parser = TestParser.new(DEBIT_CREDIT_SAMPLE)
    transactions = parser.parse_with(ExtrasDeCont::Rules::Ing.new)

    assert_equal 2, transactions.size
    assert_equal(-100.0, transactions.first.amount)
    assert_equal "RON", transactions.first.currency
  end
end
