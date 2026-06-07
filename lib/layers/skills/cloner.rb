# frozen_string_literal: true

require 'fileutils'

module Layers
  module Skills
    class Cloner
      class GitCommandFailed < Layers::Error; end
      COLLECTIONS = ['derisk_common', 'derisk_ruby', 'derisk_rails', 'derisk_layers'].freeze
      DEFAULT_BASE_URL = 'https://github.com/DeriskLabs'

      def initialize(target_dir:, base_url: DEFAULT_BASE_URL, runner: Kernel.method(:system))
        @target_dir = File.expand_path(target_dir)
        @base_url = base_url
        @runner = runner
      end

      def clone
        FileUtils.mkdir_p(target_dir)
        COLLECTIONS.to_h { |collection| [collection, clone_or_pull(collection)] }
      end


      private

      attr_reader :target_dir, :base_url, :runner

      def clone_or_pull(collection)
        destination = File.join(target_dir, collection)
        return pull(destination, collection) if File.directory?(File.join(destination, '.git'))

        run('git', 'clone', repo_url(collection), destination, collection: collection)
        :cloned
      end

      def pull(destination, collection)
        run('git', '-C', destination, 'pull', '--ff-only', collection: collection)
        :pulled
      end

      def repo_url(collection)
        "#{base_url}/AI-#{collection}.git"
      end

      def run(*command, collection:)
        return if runner.call(*command)

        fail GitCommandFailed, "#{collection}: '#{command.join(' ')}' failed."
      end
    end
  end
end
