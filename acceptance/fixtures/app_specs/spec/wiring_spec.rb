# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application wiring' do
  it 'eager loads under zeitwerk' do
    expect { Rails.application.eager_load! }.not_to raise_error
  end

  it 'routes Layers logging through Rails.logger' do
    expect(Layers::Logger.logger).to be(Rails.logger)
  end

  it 'detects the kaminari pagination adapter' do
    expect(Layers.configuration.pagination_adapter).to be(Layers::Adapters::Pagination::Kaminari)
  end
end
