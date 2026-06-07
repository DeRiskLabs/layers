# frozen_string_literal: true

module Layers
  module Generators
    module GraphqlMutationTemplates


      private

      def declaration
        "class #{file_name.camelize} < #{parent}"
      end

      def parent
        options[:parent] || "#{api_module}::Mutations::ApplicationMutation"
      end

      def body
        [*header_section, '', *payload_section, '', *wiring_section, '',
         *success_section, '', *failure_section]
      end

      def header_section
        ["description '#{description_text}'"]
      end

      def payload_section
        ["field :#{resource}, #{type_constant}, null: true,",
         "  description: 'The #{resource.humanize.downcase}'",
         '',
         'field :errors, [Types::Base::ErrorType], null: true,',
         "  description: 'Errors encountered while #{progressive_phrase}'"]
      end

      def wiring_section
        ["user_story '#{user_story_ref}'",
         'user_story_arg :current_identity']
      end

      def success_section
        ["def on_success(#{resource}: nil)",
         '  {',
         "    #{resource}: #{resource},",
         '    errors: [],',
         '  }',
         'end']
      end

      def failure_section
        ['def on_failure(errors: nil)',
         '  {',
         "    #{resource}: nil,",
         '    errors: execution_errors_for(errors),',
         '  }',
         'end']
      end

      def story_declaration
        "class #{file_name.camelize} < ApplicationUserStory"
      end

      def resource
        @resource ||= (class_path.last || file_name).singularize
      end

      def use_case_constant
        "#{api_module}.configuration.use_cases[:#{registry_key}]"
      end

      def registry_key
        [*class_path, file_name].join('_')
      end

      def container_use_case
        ['UseCases', *class_path.map(&:camelize), file_name.camelize].join('::')
      end

      def use_case_registration_line
        "config.register_use_case #{registry_key}: '#{container_use_case}'"
      end

      def initializer_path
        File.join('config/initializers', "#{api}.rb")
      end

      def type_constant
        "Types::#{resource.pluralize.camelize}::Type"
      end

      def user_story_ref
        File.join('user_stories', api, *class_path, file_name)
      end

      def graphql_field
        file_name.camelize(:lower)
      end

      def registration_line
        "field :#{file_name}, mutation: #{qualified_name}"
      end

      def qualified_name
        [api_module, 'Mutations', *class_path.map(&:camelize), file_name.camelize].join('::')
      end

      def description_text
        "#{conjugated_verb} #{indefinite_article} #{object_phrase}"
      end

      def progressive_phrase
        "#{gerund_verb} the #{object_phrase}"
      end

      def verb
        file_name.split('_').first
      end

      def object_phrase
        file_name.split('_').drop(1).join(' ').presence || resource.humanize.downcase
      end

      def conjugated_verb
        suffix = verb.match?(/(?:s|sh|ch|x|z)\z/) ? 'es' : 's'
        "#{verb.capitalize}#{suffix}"
      end

      def gerund_verb
        "#{verb.delete_suffix('e')}ing"
      end

      def indefinite_article
        object_phrase.match?(/\A[aeiou]/) ? 'an' : 'a'
      end
    end
  end
end
