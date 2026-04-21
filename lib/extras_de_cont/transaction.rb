# frozen_string_literal: true

module ExtrasDeCont
  # Models a simple bank transaction
  class Transaction
    attr_reader :date, :description, :amount

    def initialize(
      date,
      description,
      amount
    )
      @date = date
      @description = description
      @amount = amount
    end
  end
end
