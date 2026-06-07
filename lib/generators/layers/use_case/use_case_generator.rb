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
         'private', '', *execute_section]
      end

      def contract_section
        ['required :form',
         '',
         'emits success: [:form], failure: [:form] # TODO: declare the real outcome payloads']
      end

      def call_section
        ['def call',
         '  return failure(form: form) unless valid?',
         '',
         '  execute!',
         '',
         '  success(form: form) # TODO: emit the real success payload',
         'end']
      end

      def execute_section
        ['def execute!',
         '  # TODO: rename to a well named method performing the persistence in a transaction',
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

            # TODO: stub every reader the use case consumes from the form
            let(:form) { instance_double('#{form_constant}', valid?: true) }

            let(:valid_use_case_args) do
              { form: form }
            end

            let(:valid_params) { valid_listener_args.merge(valid_use_case_args) }
            let(:params) { valid_params }

            describe '.call' do

              execute do
                use_case.call
              end

              context 'when successful' do
                it 'notifies listener of success' do
                  expect(listener).to have_received(on_success_callback).with(form: form)
                end

                it 'TODO: one example per outgoing command (have_received with args)'
              end

              context 'when validation fails' do
                let(:form) { instance_double('#{form_constant}', valid?: false) }

                it 'notifies listener of failure' do
                  expect(listener).to have_received(on_failure_callback).with(form: form)
                end
              end

              context 'when persistence fails' do
                it 'TODO: notifies listener of failure when the persistence method raises'
              end
            end
          end
        RUBY
      end
    end
  end
end
