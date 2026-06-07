# frozen_string_literal: true

require 'rails/generators'
require 'generators/layers/generator_helpers'
require 'generators/layers/story_templates'

module Layers
  module Generators
    class UserStoryGenerator < Rails::Generators::NamedBase
      include GeneratorHelpers
      include StoryTemplates

      class_option :parent, type: :string, default: 'ApplicationUserStory'

      def create_user_story
        create_file File.join('app/lib/user_stories', class_path, "#{file_name}.rb"),
                    namespaced('UserStories', declaration, body)
      end

      def create_spec
        create_file File.join('spec/lib/user_stories', class_path, "#{file_name}_spec.rb"),
                    user_story_spec
      end


      private

      def declaration
        "class #{file_name.camelize} < #{options[:parent]}"
      end

      def body
        story_body
      end

      def qualified_name
        ['UserStories', *class_path.map(&:camelize), file_name.camelize].join('::')
      end

      def user_story_spec
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{qualified_name} do

            subject(:user_story) { described_class.new(**params) }

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

            let(:current_identity) { nil } # TODO: FactoryBot.create(:identity)

            let(:valid_use_case_args) do
              { current_identity: current_identity } # TODO: the inputs the story declares
            end

            let(:valid_params) { valid_listener_args.merge(valid_use_case_args) }
            let(:params) { valid_params }

            describe '.call' do

              execute do
                user_story.call
              end

              context 'when successful' do
                it 'TODO: performs the interaction (assert the visible aftermath)'

                it 'TODO: notifies listener of success with the named object'
              end

              context 'when the use case fails' do
                it 'TODO: notifies listener of failure with the errors'
              end

              context 'when the record is not found' do
                it 'TODO: notifies listener of failure (look-ups by uuid; use SecureRandom.uuid)'
              end
            end
          end
        RUBY
      end
    end
  end
end
