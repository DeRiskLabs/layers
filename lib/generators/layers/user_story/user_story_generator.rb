# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'

module Layers
  module Generators
    class UserStoryGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers

      class_option :parent, type: :string, default: 'ApplicationUserStory'

      def create_user_story
        create_file File.join('app/lib/user_stories', class_path, "#{file_name}.rb"),
                    namespaced('UserStories', declaration, body)
      end

      def create_spec
        create_file File.join('spec/lib/user_stories', class_path, "#{file_name}_spec.rb"),
                    pending_spec(qualified_name, 'testing-user-stories')
      end


      private

      def declaration
        "class #{file_name.camelize} < #{options[:parent]}"
      end

      def body
        [
          'def call',
          '  success(result: nil)',
          'end',
        ]
      end

      def qualified_name
        ['UserStories', *class_path.map(&:camelize), file_name.camelize].join('::')
      end
    end
  end
end
