# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "extras_de_cont"
  s.version = "1.5.0"
  s.licenses = ["GPLv3"]
  s.summary = "A library for extracting transactions from bank statements."
  s.description = <<~TEXT
    A library for extracting transactions from PDF bank statements and Revolut CSV exports.
    Fine tuned for Romanian bank statements.

    Repository: https://github.com/dnutiu/extras-de-cont
  TEXT
  s.authors = ["Denis Nutiu"]
  s.email = "dnutiu@nuculabs.dev"
  s.homepage = "https://nuculabs.dev"
  s.metadata = {"source_code_uri" => "https://gitlab.nuculabs.dev/dnutiu/extras-de-cont",
                 "rubygems_mfa_required" => "true"}
  s.required_ruby_version = ">= 3.0.0"

  # Files to include in the gem
  s.files = Dir["{lib, sig}/**/*", "LICENSE", "README.md", "extras_de_cont.gemspec"]

  # Optional but recommended
  s.require_paths = ["lib"]

  s.add_dependency "pdf-reader", "~> 2.15"
  s.add_dependency "csv", "~> 3.3"
  s.add_dependency "bigdecimal", "~> 3.1"
  s.add_dependency "zeitwerk", "~> 2.8"
end
