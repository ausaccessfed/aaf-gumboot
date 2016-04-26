# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gumboot/version'

Gem::Specification.new do |spec|
  spec.name          = 'aaf-gumboot'
  spec.version       = Gumboot::VERSION
  spec.authors       = ['Bradley Beddoes']
  spec.email         = ['bradleybeddoes@aaf.edu.au']
  spec.summary       = 'Kick off subject and API structure for AAF applications'
  spec.description   = 'Provides a set of shared specs and base generators to' \
                       ' ensure that all AAF ruby applications follow the' \
                       ' same basic structure and implementation for' \
                       ' subjects, RESTful APIs and access control.'
  spec.homepage      = 'http://www.aaf.edu.au'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0")

  spec.add_dependency 'accession', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'mysql2', '~> 0.3.20'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'valhammer'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-bundler'

  spec.add_development_dependency 'rails', '~> 4.2.6'
end
