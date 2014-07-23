# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbpath/version'

Gem::Specification.new do |spec|
  spec.name          = "rbpath"
  spec.version       = RbPath::VERSION
  spec.authors       = ["Alex Skryl"]
  spec.email         = ["rut216@gmail.com"]
  spec.description   = %q{A lightweight library for running XPath like queries on Ruby collections and object graphs.}
  spec.summary       = %q{A lightweight library for running XPath like queries on Ruby collections and object graphs}
  spec.homepage      = "http://github.com/skryl/rbpath"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
