# frozen_string_literal: true

require "digest"

module ExtrasDeCont
  # Models a simple bank transaction
  class Transaction
    attr_reader :date, :description, :amount, :currency, :state, :deduplication_key

    def initialize(
      date,
      description,
      amount,
      currency,
      **options
    )
      @date = date
      @description = description
      @amount = amount
      @currency = currency
      @state = options[:state]
      @deduplication_key = options[:deduplication_key] || build_deduplication_key
    end

    def reverted?
      state.to_s.casecmp?("REVERTED")
    end

    private

    def build_deduplication_key
      Digest::SHA256.hexdigest([date, description, amount, currency, state].join("\u001f"))
    end
  end
end
