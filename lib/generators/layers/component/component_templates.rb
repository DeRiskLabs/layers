# frozen_string_literal: true

module Layers
  module Generators
    module ComponentTemplates


      private

      def gemspec
        <<~RUBY
          # frozen_string_literal: true

          require_relative 'lib/#{file_name}/version'

          Gem::Specification.new do |spec|
            spec.name = '#{file_name}'
            spec.version = #{module_name}::VERSION
            spec.authors = ['']
            spec.summary = '#{module_name} bounded context'
            spec.required_ruby_version = '>= 3.1'

            spec.files = Dir.glob('lib/**/*')
            spec.require_paths = ['lib']

            spec.add_dependency 'layers'
          end
        RUBY
      end

      def gemfile
        <<~RUBY
          # frozen_string_literal: true

          source 'https://rubygems.org'

          gemspec

          gem 'rspec'
        RUBY
      end

      def root_constant
        <<~RUBY
          # frozen_string_literal: true

          require 'layers'
          require '#{file_name}/version'
          require '#{file_name}/repository_registry'
          require '#{file_name}/configuration'

          module #{module_name}
            class << self
              def configuration
                @configuration ||= Configuration.new
              end

              def configure
                yield(configuration)
              end
            end
          end
        RUBY
      end

      def configuration
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class Configuration
              attr_writer :repo

              delegate :register_repository, :register_repositories, to: :repo

              def repo
                @repo ||= RepositoryRegistry.new
              end
            end
          end
        RUBY
      end

      def repository_registry
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class RepositoryRegistry < Layers::BaseRegistry
              alias register_repository register
              alias register_repositories register
              alias remove_repository remove
            end
          end
        RUBY
      end

      def version
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            VERSION = '0.1.0'
          end
        RUBY
      end

      def spec_helper
        <<~RUBY
          # frozen_string_literal: true

          require '#{file_name}'

          RSpec.configure do |config|
            config.disable_monkey_patching!
            config.order = :random
            Kernel.srand config.seed
          end
        RUBY
      end

      def component_spec
        <<~RUBY
          # frozen_string_literal: true

          require 'spec_helper'

          RSpec.describe #{module_name} do
            it 'has a version' do
              expect(#{module_name}::VERSION).not_to be_nil
            end
          end
        RUBY
      end

      def rubocop_config
        <<~YAML
          inherit_from: ../../.rubocop.yml
        YAML
      end

      def readme
        <<~MARKDOWN
          # #{module_name}

          A bounded context consumed by the container application as an unbuilt gem.

          - Public interface: class methods on `#{module_name}` in `lib/#{file_name}.rb` —
            other contexts and the container call only these.
          - Persistence: the container owns all models; this component reaches them through
            repositories registered at boot:

            ```ruby
            #{module_name}.configure do |config|
              config.register_repository identity: 'Identity'
            end
            ```

            Component code resolves them via `#{module_name}.configuration.repo[:identity]`.
          - Consumed via the application Gemfile, never autoloaded:
            `path 'components' do gem '#{file_name}' end`.
          - Isolated suite: `bin/test_components` from the application root, or
            `bundle exec rspec` from this directory. Wire your private `layers` source into
            the Gemfile first.
        MARKDOWN
      end

      def isolation_runner
        <<~BASH
          #!/usr/bin/env bash
          set -uo pipefail

          status=0
          for component in components/*/; do
            [ -f "${component}Gemfile" ] || continue
            echo "==> ${component}"
            (cd "$component" && BUNDLE_GEMFILE=Gemfile bundle exec rspec) || status=1
          done

          exit $status
        BASH
      end
    end
  end
end
