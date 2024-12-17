# frozen_string_literal: true

$: << File.expand_path('lib')
require "mifare_access_condition_builder"

Gem::Specification.new do |spec|
  spec.name = "mifare-access-condition-builder"
  spec.version = MifareAccessConditionBuilder::VERSION
  spec.authors = ["Lars Kanis"]
  spec.email = ["lars.kanis@sincnovation.com"]

  spec.summary = "Calculate the access condition bytes of sectors of Mifare contactless chip cards"
  spec.description = "Calculate the access condition bytes of sectors of Mifare contactless chip cards "
  spec.homepage = "https://github.com/larskanis/mifare-access-condition-builder"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fxruby", "~> 1.6.20"
end
