# frozen_string_literal: true

require_relative 'lib/layers/version'

Gem::Specification.new do |spec|
  spec.name        = 'layers'
  spec.version     = Layers::VERSION
  spec.authors     = ['Richard Jordan']
  spec.email       = ['richarddjordan@gmail.com']

  spec.summary     = 'A Ruby gem for building clean, maintainable applications using a layered architecture'
  spec.description = 'Layers helps you separate business logic from framework code using message-passing and clear boundaries'
  spec.homepage    = 'https://github.com/richardjordan/layers'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'documentation_uri' => "#{spec.homepage}/blob/main/README.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir.glob('{lib,spec}/**/*') + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'naught', '~> 1.1'

  # Development dependencies
  spec.add_development_dependency 'brakeman', '~> 6.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-performance', '~> 1.18'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.22'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yard', '~> 0.9'
end
