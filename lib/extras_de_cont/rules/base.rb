# frozen_string_literal: true

module ExtrasDeCont
  module Rules
    # The base class for implementing bank specific transaction parsing rules.
    class Base
      def parse(_text)
        raise NotImplementedError, "#{self.class} must implement #parse"
      end
    end
  end
end
