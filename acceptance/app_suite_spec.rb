# frozen_string_literal: true

require_relative 'acceptance_helper'

RSpec.describe 'the skeleton app suite' do
  it 'passes, exercising the gem the way the skills teach' do
    output, status = SkeletonApp.run('bundle exec rspec')

    expect(status.success?).to be(true), proc { "app suite failed:\n#{output}" }
  end
end
