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
         'user_story_arg :current_authorization']
      end

      def success_section
        ["def on_success(#{payload_key}: nil)",
         "  #{payload_key}",
         'end']
      end

      def failure_section
        ["def on_failure(#{payload_key}: nil, errors: nil)",
         "  errors_list = Array(#{payload_key} ? #{payload_key}.errors : errors)",
         '  errors_list.map do |error|',
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
        return ['required :current_authorization', 'required :id'] if single?

        ['required :current_authorization']
      end

      def story_lookup_section
        ["def #{payload_key}", "  #{story_lookup_placeholder}", 'end']
      end

      def story_lookup_placeholder
        if single?
          "nil # TODO: find by uuid (id) via #{registry_access}, scoped via current_authorization"
        else
          "[] # TODO: ask #{registry_access}, scoped to current_authorization"
        end
      end

      def registry_access
        "#{api_module}.configuration.queries[:#{registry_key}]"
      end

      def registry_key
        [*class_path, domain].join('_')
      end

      def container_query_object
        ['Queries', *class_path.map(&:camelize), "#{domain.camelize}Query"].join('::')
      end

      def query_registration_line
        "config.register_query_object #{registry_key}: '#{container_query_object}'"
      end

      def initializer_path
        File.join('config/initializers', "#{api}.rb")
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
