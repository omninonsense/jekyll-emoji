# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll/emoji/version'

Gem::Specification.new do |spec|
  spec.name          = "jekyll-emoji"
  spec.version       = Jekyll::Emoji::VERSION
  spec.authors       = ["Nino Miletich"]
  spec.email         = ["nino@miletich.me"]

  spec.summary       = %q{Adds support for emojis to Jekyll}
  spec.homepage      = "https://github.com/omninonsense/jekyll-emoji"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.10"
  spec.add_dependency "rake", "~> 10.0"
  spec.add_dependency "jekyll", "~> 2.0"
  spec.add_dependency "yajl-ruby"
  spec.add_dependency "oga", "~> 1.2.0"
end
