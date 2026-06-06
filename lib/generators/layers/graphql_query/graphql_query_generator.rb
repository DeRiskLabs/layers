# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'
require 'generators/layers/graphql_query/graphql_query_templates'

module Layers
  module Generators
    class GraphqlQueryGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers
      include GraphqlQueryTemplates

      class_option :engine, type: :string, default: 'graph'
      class_option :parent, type: :string
      class_option :single, type: :boolean, default: false

      def create_resolver
        create_file resolver_path, namespaced_in(resolver_modules, declaration, body)
      end

      def create_user_story
        create_file user_story_path, namespaced_in(story_modules, story_declaration, story_body)
      end

      def create_spec
        create_file spec_path, pending_spec("'#{graphql_field} query'", 'testing-graphql')
      end

      def register_resolver
        unless File.exist?(query_type_path)
          return say("add to your QueryType: #{registration_line}")
        end

        inject_into_file query_type_path, "      #{registration_line}\n",
                         after: /class QueryType[^\n]*\n/
      end


      private

      def api
        options[:engine].underscore
      end

      def api_module
        api.camelize
      end

      def engine_root
        File.join('apis', api)
      end

      def single?
        options[:single]
      end

      def domain
        file_name
      end

      def resolver_name
        single? ? domain.singularize : domain
      end

      def resolver_path
        File.join(engine_root, 'app/graphql', api, 'resolvers', *class_path,
                  domain, "#{resolver_name}.rb")
      end

      def resolver_modules
        [api_module, 'Resolvers', *class_path.map(&:camelize), domain.camelize]
      end

      def user_story_path
        File.join(engine_root, 'app/lib/user_stories', api, *class_path,
                  domain, "#{story_name}.rb")
      end

      def story_modules
        ['UserStories', api_module, *class_path.map(&:camelize), domain.camelize]
      end

      def spec_path
        File.join('spec/acceptance', api, *class_path, domain, "#{resolver_name}_spec.rb")
      end

      def query_type_path
        File.join(engine_root, 'app/graphql', api, 'types/query_type.rb')
      end
    end
  end
end
