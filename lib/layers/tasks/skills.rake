# frozen_string_literal: true

require 'layers'
require 'layers/skills/installer'
require 'layers/skills/cloner'

namespace :layers do
  resolve_target = lambda do |argument, task_name|
    return File.expand_path(argument) unless argument.nil? || argument.strip.empty?

    abort "Usage: rake '#{task_name}[target_dir]'" unless $stdin.tty?
    print 'Destination directory [.ai/skills]: '
    input = $stdin.gets.to_s.chomp.strip
    File.expand_path(input.empty? ? '.ai/skills' : input)
  end

  desc 'Copy the installed ai-derisk_* skill collections into a directory'
  task :sync_skills, [:target_dir] do |task, args|
    target = resolve_target.call(args[:target_dir], task.name)
    collections = Layers::Skills::Installer.new(target_dir: target).install
    puts "Installed #{collections.join(', ')} into #{target}"
  rescue Layers::Skills::Installer::NoSkillCollections
    abort "No ai-derisk_* gems found in the current bundle.\n" \
          "Add one to your Gemfile first, e.g.: gem 'ai-derisk_layers', require: false"
  end

  desc 'Clone or update the AI-derisk_* skill repositories into a directory'
  task :clone_skills, [:target_dir] do |task, args|
    target = resolve_target.call(args[:target_dir], task.name)
    results = Layers::Skills::Cloner.new(target_dir: target).clone
    results.each { |collection, action| puts "#{action}: #{collection}" }
    puts "Skill repositories ready in #{target}"
  rescue Layers::Skills::Cloner::GitCommandFailed => e
    abort "git failed — #{e.message}"
  end
end
