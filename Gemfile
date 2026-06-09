# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  gem 'brakeman', '~> 6.0'
  gem 'bundler-audit', '~> 0.9'
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.87'
  gem 'rubocop-performance', '~> 1.20'
  gem 'rubocop-rake', '~> 0.6'
  gem 'rubocop-rspec', '~> 3.0'
  gem 'yard', '~> 0.9'
  # The toolchain gem ships the cops; needed here so the gem can lint itself.
  gem 'layers-scaffold', path: '../layers-scaffold'
end

group :development, :test do
  gem 'jazz_fingers'
  gem 'pry', '~> 0.14'
  gem 'rspec', '~> 3.12'
end

group :test do
  gem 'always_execute'
  gem 'simplecov', '~> 0.22'
end
