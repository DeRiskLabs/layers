# frozen_string_literal: true

require_relative 'acceptance_helper'

RSpec.describe 'engine standalone suites' do
  SkeletonApp::ENGINES.each do |engine|
    it "runs #{engine} in its own directory against the schema-less dummy" do
      engine_dir = File.join(SkeletonApp.root, engine)
      SkeletonApp.run!('bundle install --quiet', chdir: engine_dir)

      output, status = SkeletonApp.run('bundle exec rspec', chdir: engine_dir)

      expect(status.success?).to be(true), proc { "#{engine} suite failed:\n#{output}" }
    end
  end
end
