# frozen_string_literal: true

# Release acceptance suite (~2 min, network for rails new + bundler). Builds one
# throwaway skeleton app (gem installed from the committed HEAD of the current
# branch), copies in the fixture layer stack and its specs, runs every generator,
# and then asserts: the app's own suite passes, each generated engine's standalone
# suite passes in its own directory, and the component's isolated suite passes.
#
# Run via bin/smoke_test (or: bundle exec rspec -O acceptance/.rspec
# --pattern 'acceptance/*_spec.rb' — the pattern keeps RSpec away from the
# fixture specs, which only load inside the built app). Not part of the
# default `bundle exec rspec` run.

require_relative 'support/skeleton_app'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before(:suite) { SkeletonApp.build! }
  config.after(:suite) { SkeletonApp.destroy! }
end
