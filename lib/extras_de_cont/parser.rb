# frozen_string_literal: true

require "pdf-reader"

module ExtrasDeCont
  # Utility class for parsing a pdf file and extracting transaction data.
  class Parser
    def initialize(file)
      @file = file
    end

    # Extracts all text content from the pdf file.
    #
    # This method opens the pdf using PDF::Reader, concatenates the text from every page,
    # and returns it as a single string.
    #
    # @return [String] the full text extracted from all pages of the PDF
    def text
      reader = PDF::Reader.new(@file)
      all_pdf_text = StringIO.new

      reader.pages.each do |page|
        all_pdf_text << page.text
      end

      all_pdf_text.string
    end

    # Parses the pdf text with the requested Rule class.
    # @param rule [ExtrasDeCont::Rule] - The parsing rule specific to the bank.
    # @return [Array<ExtrasDeCont::Transaction>]
    def parse_with(rule)
      raise NotImplementedError("not yet implemented #{rule}")
    end
  end
end

