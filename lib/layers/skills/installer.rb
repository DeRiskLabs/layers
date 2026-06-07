# frozen_string_literal: true

require 'fileutils'

module Layers
  module Skills
    class Installer
      class NoSkillCollections < Layers::Error; end
      GEM_PREFIX = 'ai-derisk_'

      def self.installed_specs
        (Gem.loaded_specs.values + Gem::Specification.latest_specs(true))
          .select { |spec| spec.name.start_with?(GEM_PREFIX) }
          .uniq(&:name)
      end

      def initialize(target_dir:, specs: self.class.installed_specs)
        @target_dir = File.expand_path(target_dir)
        @specs = specs
      end

      def install
        fail NoSkillCollections, "No #{GEM_PREFIX}* gems installed." if specs.empty?

        specs.map { |spec| install_collection(spec) }.sort
      end


      private

      attr_reader :target_dir, :specs

      def install_collection(spec)
        collection = spec.name.delete_prefix('ai-')
        destination = File.join(target_dir, collection)
        FileUtils.rm_rf(destination)
        FileUtils.mkdir_p(destination)
        copy_entries(spec.full_gem_path, destination)
        collection
      end

      def copy_entries(source, destination)
        Dir.children(source).each do |entry|
          next if entry.start_with?('.') || entry.end_with?('.gemspec')

          FileUtils.cp_r(File.join(source, entry), destination)
        end
      end
    end
  end
end
