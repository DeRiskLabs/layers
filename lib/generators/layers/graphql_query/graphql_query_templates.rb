# frozen_string_literal: true

module Layers
  module Generators
    module GraphqlQueryTemplates


      private

      def declaration
        "class #{resolver_name.camelize} < #{parent}"
      end

      def parent
        options[:parent] || "#{api_module}::Resolvers::ApplicationResolver"
      end

      def body
        [*header_section, '', *wiring_section, '', *success_section, '', *failure_section]
      end

      def header_section
        return single_header_section if single?

        ["description 'Fetches #{domain.humanize.downcase}'",
         '',
         "type [#{type_constant}], null: false"]
      end

      def single_header_section
        ["description 'Fetches #{indefinite_article} #{singular_name}'",
         '',
         'argument :id, Types::Base::UuidType, required: true,',
         "  description: 'The UUID of the #{singular_name} to fetch'",
         '',
         "type #{type_constant}, null: true"]
      end

      def wiring_section
        ["user_story '#{user_story_ref}'",
         'user_story_arg :current_identity']
      end

      def success_section
        ["def on_success(#{payload_key}: nil)",
         "  #{payload_key}",
         'end']
      end

      def failure_section
        ['def on_failure(errors: nil)',
         '  errors&.map do |error|',
         '    GraphQL::ExecutionError.new(error.message)',
         '  end',
         'end']
      end

      def story_declaration
        "class #{story_name.camelize} < ApplicationUserStory"
      end

      def story_body
        [*story_inputs_section, '',
         "emits success: [:#{payload_key}], failure: [:errors] # TODO: confirm the payloads",
         '',
         'def call',
         "  success(#{payload_key}: #{payload_key})",
         'end',
         '', '',
         'private',
         '',
         *story_lookup_section]
      end

      def story_inputs_section
        return ['required :current_identity', 'required :id'] if single?

        ['required :current_identity']
      end

      def story_lookup_section
        ["def #{payload_key}", "  #{story_lookup_placeholder}", 'end']
      end

      def story_lookup_placeholder
        if single?
          'nil # TODO: find by public uuid (id), scoped to current_identity'
        else
          '[] # TODO: the identity-scoped collection (usually a query object)'
        end
      end

      def story_name
        single? ? 'fetch' : 'fetch_all'
      end

      def payload_key
        single? ? domain.singularize : domain
      end

      def user_story_ref
        File.join('user_stories', api, *class_path, domain, story_name)
      end

      def type_constant
        "Types::#{domain.camelize}::Type"
      end

      def graphql_field
        resolver_name.camelize(:lower)
      end

      def registration_line
        "field :#{resolver_name}, resolver: #{qualified_name}"
      end

      def qualified_name
        [*resolver_modules, resolver_name.camelize].join('::')
      end

      def singular_name
        domain.singularize.humanize.downcase
      end

      def indefinite_article
        singular_name.match?(/\A[aeiou]/) ? 'an' : 'a'
      end
    end
  end
end
