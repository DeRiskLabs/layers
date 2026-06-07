# frozen_string_literal: true

module Layers
  module Generators
    module EngineTemplates


      private

      def gemspec_content
        <<~RUBY
          # frozen_string_literal: true

          require_relative 'lib/#{file_name}/version'

          Gem::Specification.new do |spec|
            spec.name        = '#{file_name}'
            spec.version     = #{class_name}::VERSION
            spec.authors     = ['']
            spec.summary     = '#{class_name} engine'

            spec.files = Dir.chdir(File.expand_path(__dir__)) do
              Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
            end

            spec.add_dependency 'layers'
            spec.add_dependency 'rails', '>= #{rails_version}'
          end
        RUBY
      end

      def gemfile_content
        <<~RUBY
          # frozen_string_literal: true

          source 'https://rubygems.org'

          gemspec

          # TODO: drop the git source once layers is publicly available
          gem 'layers', git: 'git@github.com:DeRiskLabs/layers.git'

          group :development, :test do
            gem 'always_execute'
            gem 'rspec-rails'
          end
        RUBY
      end

      def rakefile_content
        <<~RUBY
          # frozen_string_literal: true

          require 'bundler/setup'
        RUBY
      end

      def readme_content
        <<~MARKDOWN
          # #{class_name}

          TODO: describe the slice this engine owns — its purpose, its public boundary, and
          what it deliberately does not do.
        MARKDOWN
      end

      def root_file_content
        <<~RUBY
          # frozen_string_literal: true

          require 'layers'
          require '#{file_name}/version'
          require '#{file_name}/use_case_registry'
          require '#{file_name}/query_object_registry'
          require '#{file_name}/configuration'
          require '#{file_name}/engine'

          module #{class_name}
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

      def use_case_registry_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class UseCaseRegistry < Layers::BaseRegistry
              alias register_use_case register
              alias register_use_cases register
              alias remove_use_case remove
            end
          end
        RUBY
      end

      def query_object_registry_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class QueryObjectRegistry < Layers::BaseRegistry
              alias register_query_object register
              alias register_query_objects register
              alias remove_query_object remove
            end
          end
        RUBY
      end

      def configuration_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class Configuration
              attr_writer :use_cases, :queries

              delegate :register_use_case, :register_use_cases, to: :use_cases
              delegate :register_query_object, :register_query_objects, to: :queries

              def use_cases
                @use_cases ||= UseCaseRegistry.new
              end

              def queries
                @queries ||= QueryObjectRegistry.new
              end
            end
          end
        RUBY
      end

      def container_initializer_content
        <<~RUBY
          # frozen_string_literal: true

          #{class_name}.configure do |config|
            # TODO: register the commands and queries this engine is allowed to reach
            # config.register_use_case create_thing: 'UseCases::Things::Create'
            # config.register_query_object things: 'Queries::ThingsQuery'
          end
        RUBY
      end

      def version_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            VERSION = '0.1.0'
          end
        RUBY
      end

      def engine_content
        api? ? api_engine_content : feature_engine_content
      end

      def feature_engine_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class Engine < ::Rails::Engine
              isolate_namespace #{class_name}

              config.generators do |g|
                g.test_framework :rspec
                g.fixture_replacement :factory_bot
                g.factory_bot dir: 'spec/factories'
              end

              initializer '#{file_name}.middleware' do |_app|
                config.middleware.delete ActionDispatch::Cookies
                config.middleware.delete ActionDispatch::Session::CookieStore
                config.middleware.delete ActionDispatch::Flash

                middleware.use ActionDispatch::Cookies
                middleware.use Rails.application.config.session_store,
                               Rails.application.config.session_options
                middleware.use ActionDispatch::Flash
                middleware.use Rack::MethodOverride
              end

              config.i18n.load_path += Dir[root.join('config', 'locales', '**', '*.{rb,yml}')]
            end
          end
        RUBY
      end

      def api_engine_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class Engine < ::Rails::Engine
              isolate_namespace #{class_name}

              config.api_only = true

              initializer '#{file_name}.api_mode' do |_app|
                config.debug_exception_response_format = :api
                config.action_controller.default_protect_from_forgery = false

                config.session_store = :null_store
                config.middleware.delete ActionDispatch::Cookies
                config.middleware.delete ActionDispatch::Session::CookieStore
                config.middleware.delete ActionDispatch::Flash
              end

              initializer '#{file_name}.set_api_format' do |_app|
                ActiveSupport.on_load(:action_controller) do
                  config.default_render_format = :json
                end
              end
            end
          end
        RUBY
      end

      def routes_content
        api? ? api_routes_content : feature_routes_content
      end

      def feature_routes_content
        <<~RUBY
          # frozen_string_literal: true

          #{class_name}::Engine.routes.draw do
            scope '#{file_name}' do
              # TODO: the engine's routes
            end
          end
        RUBY
      end

      def api_routes_content
        <<~RUBY
          # frozen_string_literal: true

          #{class_name}::Engine.routes.draw do
            # TODO: the engine's routes
          end
        RUBY
      end

      def application_controller_content
        <<~RUBY
          # frozen_string_literal: true

          module #{class_name}
            class ApplicationController < #{controller_parent}
            end
          end
        RUBY
      end

      def controller_parent
        api? ? 'ActionController::API' : 'ActionController::Base'
      end

      def use_case_base_content
        <<~RUBY
          # frozen_string_literal: true

          module UseCases
            module #{class_name}
              class BaseUseCase < Layers::BaseLayer
              end
            end
          end
        RUBY
      end

      def user_story_base_content
        <<~RUBY
          # frozen_string_literal: true

          module UserStories
            module #{class_name}
              class BaseUserStory < Layers::BaseLayer
              end
            end
          end
        RUBY
      end

      def rspec_config_content
        <<~TEXT
          --require rails_helper
          --color
          --format documentation
        TEXT
      end

      def spec_helper_content
        <<~RUBY
          # frozen_string_literal: true

          require 'always_execute'

          RSpec.configure do |config|
            config.disable_monkey_patching!
            config.order = :random
            Kernel.srand config.seed
          end
        RUBY
      end

      def rails_helper_content
        <<~RUBY
          # frozen_string_literal: true

          ENV['RAILS_ENV'] ||= 'test'

          require 'spec_helper'
          require_relative 'dummy/config/environment'
          require 'rspec/rails'
        RUBY
      end

      def dummy_application_content
        <<~RUBY
          # frozen_string_literal: true

          require 'action_controller/railtie'
          require '#{file_name}'

          module Dummy
            class Application < Rails::Application
              config.root = File.expand_path('..', __dir__)
              config.load_defaults Rails::VERSION::STRING.to_f
              config.eager_load = false
              config.hosts.clear
              config.secret_key_base = 'dummy'
              #{dummy_session_line}
            end
          end
        RUBY
      end

      def dummy_session_line
        return 'config.api_only = true' if api?

        "config.session_store :cookie_store, key: '_dummy_session'"
      end

      def dummy_environment_content
        <<~RUBY
          # frozen_string_literal: true

          require_relative 'application'

          Rails.application.initialize!
        RUBY
      end

      def dummy_routes_content
        <<~RUBY
          # frozen_string_literal: true

          Rails.application.routes.draw do
            mount #{class_name}::Engine, at: '#{mount_path}'
          end
        RUBY
      end

      def root_spec_content
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{class_name} do
            it 'carries a use case registry' do
              expect(described_class.configuration.use_cases).to be_a(#{class_name}::UseCaseRegistry)
            end

            it 'carries a query object registry' do
              expect(described_class.configuration.queries).to be_a(#{class_name}::QueryObjectRegistry)
            end
          end
        RUBY
      end

      def test_suite_content
        <<~BASH
          #!/usr/bin/env bash
          set -uo pipefail

          status=0

          echo "==> container suite"
          bundle exec rspec || status=1

          for slice in components/*/ engines/*/ apis/*/; do
            [ -f "${slice}Gemfile" ] || continue
            echo "==> ${slice}"
            (cd "$slice" \\
              && (BUNDLE_GEMFILE=Gemfile bundle check >/dev/null 2>&1 \\
                  || BUNDLE_GEMFILE=Gemfile bundle install --quiet) \\
              && BUNDLE_GEMFILE=Gemfile bundle exec rspec) || status=1
          done

          exit $status
        BASH
      end

      def rails_version
        defined?(Rails) && Rails.respond_to?(:version) ? Rails.version : '8.0'
      end
    end
  end
end
