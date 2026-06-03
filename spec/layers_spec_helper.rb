# frozen_string_literal: true

require 'always_execute'
require 'pry'
require 'layers'

RSpec.configure do |config|
  config.filter_run focus: true
  config.order = :random
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
