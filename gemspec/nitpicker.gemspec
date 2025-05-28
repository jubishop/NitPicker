require_relative '../lib/nitpicker/version'

Gem::Specification.new do |spec|
  spec.name          = "nitpicker-code-review"
  spec.version       = NitPicker::VERSION
  spec.authors       = ["Justin Bishop"]
  spec.email         = ["jubishop@gmail.com"]
  spec.summary       = "AI-powered Git code review tool"
  spec.description   = "NitPicker is a command-line tool that uses AI to review your staged Git changes and provide constructive feedback"
  spec.homepage      = "https://github.com/jubishop/NitPicker"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w[README.md LICENSE config/prompt]
  spec.bindir        = "bin"
  spec.executables   = ["nitpicker"]

  spec.add_dependency "json", "~> 2.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end