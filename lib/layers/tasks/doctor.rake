# frozen_string_literal: true

require 'layers'
require 'layers/doctor'

namespace :layers do
  desc 'Check that every slice (engine, api, component) is a well-formed bounded context'
  task :doctor do
    doctor = Layers::Doctor.new(root: defined?(Rails) ? Rails.root.to_s : Dir.pwd)

    if doctor.ok?
      puts 'layers:doctor — no structural problems found.'
    else
      puts 'layers:doctor — problems found:'
      doctor.problems.each { |problem| puts "  #{problem.slice}: #{problem.message}" }
      abort
    end
  end
end
