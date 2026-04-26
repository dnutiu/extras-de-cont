# frozen_string_literal: true

module ExtrasDeCont
  module Rules
    class Base
      def parse(_text)
        raise NotImplementedError, "#{self.class} must implement #parse"
      end
    end
  end
end
