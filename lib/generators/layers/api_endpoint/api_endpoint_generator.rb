# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'
require 'generators/layers/story_templates'
require 'generators/layers/api_endpoint/api_endpoint_templates'

module Layers
  module Generators
    # Scaffolds one REST/JSON:API command endpoint (create/update/destroy) as a
    # vertical slice across the container and an api engine:
    #   container — use case (+ its form peer) and their specs
    #   engine    — user story (the fast exit, resolving the use case via the
    #               registry), controller action, serializer, route, request +
    #               routing specs, and the use-case registration in the engine
    #               initializer.
    # Reads (index/show) are CQS-separate (query objects + serializer, no command
    # path) and out of scope.
    class ApiEndpointGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers
      include StoryTemplates
      include ApiEndpointTemplates

      class_option :engine, type: :string, default: 'v1'

      def generate_container_layers
        invoke 'layers:use_case', [target_name]
        invoke 'layers:form', [target_name]
      end

      def create_user_story
        create_file story_path,
                    namespaced_in(story_modules, story_declaration, story_body)
      end

      def create_controller
        if File.exist?(File.join(destination_root, controller_path))
          inject_into_class controller_path, controller_class, "#{controller_action_indented}\n"
        else
          create_file controller_path,
                      namespaced_in([api_module], controller_declaration, controller_action_lines)
        end
      end

      def create_serializer
        return if File.exist?(File.join(destination_root, serializer_path))

        create_file serializer_path, serializer_content
      end

      def add_route
        unless File.exist?(File.join(destination_root, routes_path))
          return say("add to #{routes_path}: #{route_line}")
        end

        inject_into_file routes_path, "  #{route_line}\n",
                         after: /\.routes\.draw do[^\n]*\n/
      end

      def register_use_case
        unless File.exist?(File.join(destination_root, initializer_path))
          return say("register in #{initializer_path}: #{use_case_registration_line}")
        end

        inject_into_file initializer_path, "  #{use_case_registration_line}\n",
                         after: /\.configure do \|config\|[^\n]*\n/
      end

      def create_specs
        create_file request_spec_path, request_spec
        create_file routing_spec_path, routing_spec
      end


      private

      def target_name
        [*class_path, file_name].join('/')
      end

      def api
        options[:engine].underscore
      end

      def api_module
        api.camelize
      end

      def engine_root
        File.join('apis', api)
      end

      def story_modules
        ['UserStories', api_module, *class_path.map(&:camelize)]
      end

      def story_path
        File.join(engine_root, 'app/lib/user_stories', api, *class_path, "#{file_name}.rb")
      end

      def controller_path
        File.join(engine_root, 'app/controllers', api, "#{resource.pluralize}_controller.rb")
      end

      def serializer_path
        File.join(engine_root, 'app/serializers', api, "#{resource}_serializer.rb")
      end

      def routes_path
        File.join(engine_root, 'config/routes.rb')
      end

      def initializer_path
        File.join('config/initializers', "#{api}.rb")
      end

      def request_spec_path
        File.join(engine_root, 'spec/requests', api, "#{resource.pluralize}_spec.rb")
      end

      def routing_spec_path
        File.join(engine_root, 'spec/routing', api, "#{resource.pluralize}_routing_spec.rb")
      end
    end
  end
end
