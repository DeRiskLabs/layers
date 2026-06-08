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
                    use_case_spec
      end


      private

      def declaration
        "class #{file_name.camelize} < #{options[:parent]}"
      end

      def body
        [*contract_section, '', 'delegate :valid?, to: :form', '', *call_section, '', '',
         'private', '', *form_section, '', *execute_section]
      end

      def contract_section
        ['required :name # TODO: the raw inputs this use case receives',
         '',
         'emits success: [:thing], failure: [:form] # TODO: name the success payload object']
      end

      def call_section
        ['def call',
         '  return failure(form: form) unless valid?',
         '',
         '  execute!',
         '',
         '  success(thing: nil) # TODO: emit the persisted object',
         'end']
      end

      def form_section
        ['def form',
         "  @form ||= #{form_constant}.new(name: name) # TODO: build the peer form",
         'end']
      end

      def execute_section
        ['def execute!',
         "  # TODO: persist the form's objects in a transaction",
         'end']
      end

      def qualified_name
        ['UseCases', *class_path.map(&:camelize), file_name.camelize].join('::')
      end

      def form_constant
        ['Forms', *class_path.map(&:camelize), "#{file_name.camelize}Form"].join('::')
      end

      def use_case_spec
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{qualified_name} do

            subject(:use_case) { described_class.new(**params) }

            let(:listener) { instance_spy('Listener') }
            let(:on_success_callback) { :on_success }
            let(:on_failure_callback) { :on_failure }

            let(:valid_listener_args) do
              {
                listener: listener,
                on_success: on_success_callback,
                on_failure: on_failure_callback,
              }
            end

            let(:valid_use_case_args) do
              { name: 'TODO' } # TODO: the raw inputs the use case declares
            end

            let(:valid_params) { valid_listener_args.merge(valid_use_case_args) }
            let(:params) { valid_params }

            describe '.call' do

              execute do
                use_case.call
              end

              context 'when successful' do
                it 'TODO: notifies the listener of success with the persisted object'
              end

              context 'when validation fails' do
                it 'TODO: notifies the listener of failure carrying the form'
              end

              context 'when persistence fails' do
                it 'TODO: notifies the listener of failure'
              end
            end
          end
        RUBY
      end
    end
  end
end
