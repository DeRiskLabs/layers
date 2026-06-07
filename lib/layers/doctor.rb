# frozen_string_literal: true

module Layers
  # Structural checks for a layers application: every slice (engine, api engine,
  # component) is a well-formed, path-consumed, standalone-testable bounded
  # context. Reports problems; does not fix them. Driven by the layers:doctor
  # rake task, which exits non-zero when problems are found.
  class Doctor
    SLICE_DIRS = ['engines', 'apis', 'components'].freeze

    Problem = Struct.new(:slice, :message)

    def initialize(root: Dir.pwd)
      @root = root
    end

    def problems
      @problems ||= slices.flat_map { |slice| check(slice) } + suite_runner_problems
    end

    def ok?
      problems.empty?
    end


    private

    attr_reader :root

    def slices
      SLICE_DIRS.flat_map { |dir| slices_in(dir) }.sort
    end

    def slices_in(dir)
      path = File.join(root, dir)
      return [] unless Dir.exist?(path)

      Dir.children(path)
         .map { |name| File.join(dir, name) }
         .select { |slice| File.directory?(File.join(root, slice)) }
    end

    def check(slice)
      [
        gemfile_problem(slice),
        path_block_problem(slice),
        spec_dir_problem(slice),
      ].compact
    end

    def gemfile_problem(slice)
      return if File.exist?(File.join(root, slice, 'Gemfile'))

      Problem.new(slice, 'has no Gemfile — a slice is an unbuilt gem with its own bundle')
    end

    def path_block_problem(slice)
      family = slice.split('/').first
      gem_name = File.basename(slice)
      return if gemfile_declares?(family, gem_name)

      Problem.new(slice, "is not consumed via `path '#{family}' do gem '#{gem_name}' end` " \
                         'in the root Gemfile')
    end

    def spec_dir_problem(slice)
      return if Dir.exist?(File.join(root, slice, 'spec'))

      Problem.new(slice, 'has no spec/ directory — a bounded slice owns its specs')
    end

    def suite_runner_problems
      return [] if slices.empty?
      return [] if File.exist?(File.join(root, 'bin/test_suite'))

      [Problem.new('(root)', 'has slices but no bin/test_suite to run them all')]
    end

    def gemfile_declares?(family, gem_name)
      return false unless File.exist?(root_gemfile)

      contents = File.read(root_gemfile)
      block = contents[/path ['"]#{Regexp.escape(family)}['"] do(.*?)\n\s*end/m, 1]
      block&.include?("gem '#{gem_name}'") || block&.include?("gem \"#{gem_name}\"")
    end

    def root_gemfile
      File.join(root, 'Gemfile')
    end
  end
end
