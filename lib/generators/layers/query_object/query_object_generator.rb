# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'

module Layers
  module Generators
    class QueryObjectGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers

      class_option :parent, type: :string, default: 'ApplicationQuery'

      def create_query_object
        create_file File.join('app/lib/queries', class_path, "#{query_file_name}.rb"),
                    namespaced('Queries', declaration, body)
      end

      def create_spec
        create_file File.join('spec/lib/queries', class_path, "#{query_file_name}_spec.rb"),
                    pending_spec(qualified_name, 'testing-query-objects')
      end


      private

      def query_file_name
        file_name.end_with?('_query') ? file_name : "#{file_name}_query"
      end

      def declaration
        "class #{query_file_name.camelize} < #{options[:parent]}"
      end

      def body
        [
          "relation_class '#{file_name.delete_suffix('_query').singularize.camelize}'",
          '',
          '',
          'private',
          '',
          'def build_relation_defaults!',
          '  @relation = relation',
          'end',
        ]
      end

      def qualified_name
        ['Queries', *class_path.map(&:camelize), query_file_name.camelize].join('::')
      end
    end
  end
end
