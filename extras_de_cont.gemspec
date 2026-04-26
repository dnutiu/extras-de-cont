# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "extras_de_cont"
  s.version = "0.1.0"
  s.licenses = ["GPLv3"]
  s.summary = "A simple library which helps you extract transactions from a PDF bank statement."
  s.description = <<~TEXT
    "A simple library which helps you extract transactions from a PDF bank statement.
    Fine tuned for Romanian bank statements."
  TEXT
  s.authors = ["Denis Nutiu"]
  s.email = "dnutiu@nuculabs.dev"
  s.homepage = "https://nuculabs.dev"
  s.metadata = {"source_code_uri" => "https://gitlab.nuculabs.dev/dnutiu/extras-de-cont"}
  s.required_ruby_version = ">= 3.0.0"

  # Files to include in the gem
  s.files = Dir["{lib, sig}/**/*", "LICENSE", "README.md", "extras_de_cont.gemspec"]

  # Optional but recommended
  s.require_paths = ["lib"]

  s.add_dependency "pdf-reader", "~> 2.15"
end
