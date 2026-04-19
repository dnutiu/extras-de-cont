# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "extrasdecont"
  s.version = "0.1.0"
  s.licenses = ["GPLv3"]
  s.summary = "A simple library which helps you extract transactions from a PDF bank statement."
  s.description = "A simple library which helps you extract transactions from a PDF bank statement. Fine tuned for Romanian bank statements."
  s.authors = ["Denis Nutiu"]
  s.email = "dnutiu@nuculabs.dev"
  s.homepage = "https://nuculabs.dev"
  s.metadata = {"source_code_uri" => "https://github.com/example/example"}
  s.required_ruby_version = ">= 3.0.0"

  # Files to include in the gem
  s.files = Dir["lib/**/*.rb"] +
    Dir["*.md"] +
    ["LICENSE", "extrasdecont.gemspec"] # adjust filename if needed

  # Optional but recommended
  s.require_paths = ["lib"]
end
