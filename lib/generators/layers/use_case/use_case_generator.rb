# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'

module Layers
  module Generators
    class UseCaseGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers

      class_option :parent, type: :string, default: 'ApplicationUseCase'

      def create_use_case
        create_file File.join('app/lib/use_cases', class_path, "#{file_name}.rb"),
                    namespaced('UseCases', declaration, body)
      end

      def create_spec
        create_file File.join('spec/lib/use_cases', class_path, "#{file_name}_spec.rb"),
                    pending_spec(qualified_name, 'testing-use-cases')
      end


      private

      def declaration
        "class #{file_name.camelize} < #{options[:parent]}"
      end

      def body
        [
          'required :form',
          '',
          'delegate :valid?, to: :form',
          '',
          'def call',
          '  return failure(form: form) unless valid?',
          '',
          '  success(form: form)',
          'end',
        ]
      end

      def qualified_name
        ['UseCases', *class_path.map(&:camelize), file_name.camelize].join('::')
      end
    end
  end
end
