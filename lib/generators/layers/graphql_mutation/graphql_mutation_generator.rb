# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'
require 'generators/layers/story_templates'
require 'generators/layers/graphql_mutation/graphql_mutation_templates'

module Layers
  module Generators
    class GraphqlMutationGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers
      include StoryTemplates
      include GraphqlMutationTemplates

      class_option :engine, type: :string, default: 'graph'
      class_option :parent, type: :string

      def create_mutation
        create_file mutation_path, namespaced("#{api_module}::Mutations", declaration, body)
      end

      def create_user_story
        create_file user_story_path,
                    namespaced("UserStories::#{api_module}", story_declaration, story_body)
      end

      def create_spec
        create_file spec_path,
                    pending_spec("'#{graphql_field} mutation'", 'testing-graphql',
                                 ['success', 'validation failure', 'authentication required'])
      end

      def register_mutation
        unless File.exist?(mutation_type_path)
          return say("add to your MutationType: #{registration_line}")
        end

        inject_into_file mutation_type_path, "      #{registration_line}\n",
                         after: /class MutationType[^\n]*\n/
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

      def mutation_path
        File.join(engine_root, 'app/graphql', api, 'mutations', *class_path, "#{file_name}.rb")
      end

      def user_story_path
        File.join(engine_root, 'app/lib/user_stories', api, *class_path, "#{file_name}.rb")
      end

      def spec_path
        File.join('spec/acceptance', api, *class_path, "#{file_name}_spec.rb")
      end

      def mutation_type_path
        File.join(engine_root, 'app/graphql', api, 'types/mutation_type.rb')
      end
    end
  end
end
