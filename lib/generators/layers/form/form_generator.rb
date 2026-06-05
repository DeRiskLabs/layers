# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'

module Layers
  module Generators
    class FormGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers

      def create_form
        create_file File.join('app/lib/forms', class_path, "#{form_file_name}.rb"),
                    namespaced('Forms', declaration, body)
      end

      def create_spec
        create_file File.join('spec/lib/forms', class_path, "#{form_file_name}_spec.rb"),
                    pending_spec(qualified_name, 'testing-form-objects')
      end


      private

      def form_file_name
        file_name.end_with?('_form') ? file_name : "#{file_name}_form"
      end

      def declaration
        "class #{form_file_name.camelize}"
      end

      def body
        ['include ActiveModel::Model']
      end

      def qualified_name
        ['Forms', *class_path.map(&:camelize), form_file_name.camelize].join('::')
      end
    end
  end
end
