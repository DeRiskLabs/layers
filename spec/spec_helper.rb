require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  minimum_coverage 95

  add_group 'Core', 'lib/layers'
  add_group 'Support', 'lib/support'
end

require 'bundler/setup'
require 'layers'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Enable focused tests with fit, fdescribe, and fcontext
  config.filter_run_when_matching :focus

  # Run all tests when none match the provided filter
  config.run_all_when_everything_filtered = true
end
