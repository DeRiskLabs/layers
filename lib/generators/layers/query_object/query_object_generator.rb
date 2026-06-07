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
                    query_spec
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
          '  @relation = relation # TODO: apply the default scope (ordering, identity scoping)',
          'end',
        ]
      end

      def qualified_name
        ['Queries', *class_path.map(&:camelize), query_file_name.camelize].join('::')
      end

      def query_spec
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{qualified_name} do

            subject(:query) { described_class.new(**query_options) }

            let(:query_options) do
              {
                # TODO: the scope this query is constructed with (e.g. identity: identity)
              }
            end

            describe '#all' do

              execute(:results) do
                query.all
              end

              it 'TODO: returns only records in scope (one in-scope, one out-of-scope record)'

              context 'when nothing is in scope' do
                it 'TODO: returns an empty collection'
              end
            end

            # TODO: one describe per refiner - assert it returns the query (be(query))
            # and refines the relation
          end
        RUBY
      end
    end
  end
end
