# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require_relative '../config/environment'
require 'rspec/rails'

ActiveRecord::Schema.define do
  create_table :widgets, force: true do |t|
    t.string :name
    t.timestamps
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
