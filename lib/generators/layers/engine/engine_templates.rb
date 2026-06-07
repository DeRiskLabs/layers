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

          require '#{file_name}/version'
          require '#{file_name}/engine'

          module #{class_name}
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

      def rails_version
        defined?(Rails) && Rails.respond_to?(:version) ? Rails.version : '8.0'
      end
    end
  end
end
