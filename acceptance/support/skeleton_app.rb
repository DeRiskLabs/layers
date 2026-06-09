# frozen_string_literal: true

require 'bundler'
require 'fileutils'
require 'open3'
require 'tmpdir'

class SkeletonApp
  class BuildFailure < StandardError; end

  RAILS_NEW_FLAGS = '--api --quiet --skip-test --skip-system-test --skip-action-mailer ' \
                    '--skip-action-mailbox --skip-action-text --skip-active-storage ' \
                    '--skip-action-cable --skip-bootsnap --skip-git --skip-kamal ' \
                    '--skip-solid --skip-ci --skip-rubocop --skip-brakeman ' \
                    '--skip-docker --skip-jbuilder --skip-dev-gems --skip-bundle'

  class << self
    attr_reader :root

    def build!
      return if @root

      @workdir = Dir.mktmpdir('layers_acceptance')
      @root = File.join(@workdir, 'skeleton_app')

      generate_rails_app
      wire_gemfile
      copy_fixtures('app_files')
      run!('bundle install --quiet')
      copy_fixtures('app_specs')
    end

    def destroy!
      FileUtils.remove_entry(@workdir) if @workdir
      @workdir = nil
      @root = nil
    end

    def gem_root
      @gem_root ||= File.expand_path('../..', __dir__)
    end

    def run!(command, chdir: root)
      output, status = run(command, chdir: chdir)
      fail BuildFailure, "`#{command}` failed in #{chdir}:\n#{output}" unless status.success?

      output
    end

    def run(command, chdir: root)
      Bundler.with_unbundled_env do
        Open3.capture2e(command, chdir: chdir)
      end
    end


    private

    def generate_rails_app
      run!("rails new skeleton_app #{RAILS_NEW_FLAGS}", chdir: @workdir)
    end

    def wire_gemfile
      File.open(File.join(root, 'Gemfile'), 'a') do |gemfile|
        gemfile.puts
        gemfile.puts "gem 'kaminari'"
        gemfile.puts "gem 'layers', git: '#{gem_root}', branch: '#{gem_branch}'"
        gemfile.puts
        gemfile.puts 'group :development, :test do'
        gemfile.puts "  gem 'always_execute'"
        gemfile.puts "  gem 'rspec-rails'"
        gemfile.puts 'end'
      end
    end

    def gem_branch
      @gem_branch ||= run!('git rev-parse --abbrev-ref HEAD', chdir: gem_root).strip
    end

    def copy_fixtures(set)
      source = File.join(__dir__, '..', 'fixtures', set)
      Dir.glob(File.join(source, '**', '*'), File::FNM_DOTMATCH).each do |file|
        next unless File.file?(file)

        destination = File.join(root, file.delete_prefix("#{source}/"))
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(file, destination)
      end
    end
  end
end
