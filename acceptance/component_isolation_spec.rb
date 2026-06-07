# frozen_string_literal: true

require_relative 'acceptance_helper'

RSpec.describe 'component isolated suite' do
  it 'runs the generated component suite in its own directory' do
    component_dir = File.join(SkeletonApp.root, 'components/billing')
    SkeletonApp.run!('bundle install --quiet', chdir: component_dir)

    output, status = SkeletonApp.run('bundle exec rspec', chdir: component_dir)

    expect(status.success?).to be(true), proc { "component suite failed:\n#{output}" }
  end
end
