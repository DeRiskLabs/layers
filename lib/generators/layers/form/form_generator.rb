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
                    form_spec
      end


      private

      def form_file_name
        file_name.end_with?('_form') ? file_name : "#{file_name}_form"
      end

      def declaration
        "class #{form_file_name.camelize}"
      end

      def body
        [*header_section, '', '', *error_messages_section, '', '', *builders_placeholder,
         '', '', *duck_typing_section, '', '', *private_section]
      end

      def header_section
        ['include ActiveModel::Model',
         '',
         'attr_writer :persisted',
         '# TODO: add form attributes with one accessor per input',
         '# attr_accessor :attribute',
         '',
         '# TODO: perform form validations (messages via I18n.t)',
         '# validates :attribute, presence: true']
      end

      def error_messages_section
        ['def form_error_messages',
         '  errors.select do |error|',
         '    report_full_errors_for.include? error.attribute',
         '  end.map(&:full_message).compact.reject(&:empty?)',
         'end']
      end

      def builders_placeholder
        ['# TODO: memoized builders for the domain objects the use case will persist']
      end

      def duck_typing_section
        ['def new_record?',
         '  !persisted?',
         'end',
         '',
         'def persisted?',
         '  @persisted ||= false',
         'end']
      end

      def private_section
        ['private',
         '',
         'def report_full_errors_for',
         '  %i[] # TODO: whitelist the attributes whose errors users see',
         'end']
      end

      def form_spec
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{qualified_name} do

            let(:form_attributes) do
              {
                # TODO: define form attributes here
              }
            end


            subject(:form) do
              described_class.new(**form_attributes)
            end


            describe 'Attributes' do
              # Follow skill: testing-form-objects
            end

            describe 'Form Duck Typing' do
              it { is_expected.to respond_to(:errors) }
              it { is_expected.to respond_to(:new_record?) }
              it { is_expected.to respond_to(:persisted?) }
              it { is_expected.to respond_to(:valid?) }
            end

            describe 'Validations' do
              # TODO: test validations here

              context 'TODO: test validations in separate contexts'
            end

            describe '#form_error_messages' do
              execute do
                form.valid?
              end

              context 'TODO: test error messages for each failure'
            end

          end
        RUBY
      end

      def qualified_name
        ['Forms', *class_path.map(&:camelize), form_file_name.camelize].join('::')
      end
    end
  end
end
