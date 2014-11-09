# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'luminoso_api/version'

Gem::Specification.new do |spec|
  spec.name          = "luminoso_api"
  spec.version       = LuminosoClient::VERSION
  spec.authors       = ["Avril Kenney"]
  spec.email         = ["akenney@lumino.so"]
  spec.summary       = %q{Ruby wrapper for the Luminoso API}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/LuminosoInsight/luminoso-api-client-ruby/"
  spec.license       = ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "rest_client"
end
