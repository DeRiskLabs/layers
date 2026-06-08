# frozen_string_literal: true

module Layers
  module Generators
    module ApiEndpointTemplates


      private

      # --- engine-resident user story (story_templates + registry override) ---

      def story_declaration
        "class #{file_name.camelize} < BaseUserStory"
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

      # --- controller ---

      def controller_declaration
        "class #{controller_class} < ApplicationController"
      end

      def controller_class
        "#{resource.pluralize.camelize}Controller"
      end

      def controller_action_indented
        controller_action_lines.map { |line| line.empty? ? '' : "      #{line}" }.join("\n")
      end

      def controller_action_lines
        [*action_method_lines, '', *success_callback_lines, '', *failure_callback_lines]
      end

      def action_method_lines
        ["def #{file_name}",
         "  #{story_constant}.call(",
         '    current_authorization: current_authorization,',
         '    listener: self,',
         "    on_success: :#{file_name}_succeeded,",
         "    on_failure: :#{file_name}_failed,",
         '    # TODO: permitted params the story forwards to the use case',
         '  )',
         'end']
      end

      def success_callback_lines
        ["def #{file_name}_succeeded(#{resource}:)",
         "  render_json_api(#{resource}, serializer: #{serializer_class},",
         "                  status: :#{success_status})",
         'end']
      end

      def failure_callback_lines
        ["def #{file_name}_failed(errors: nil)",
         '  render_json_api_errors(errors)',
         'end']
      end

      def story_constant
        ['UserStories', api_module, *class_path.map(&:camelize), file_name.camelize].join('::')
      end

      def success_status
        file_name == 'create' ? 'created' : 'ok'
      end

      # --- serializer ---

      def serializer_class
        "#{api_module}::#{resource.camelize}Serializer"
      end

      def serializer_content
        namespaced_in([api_module],
                      "class #{resource.camelize}Serializer",
                      ['include JSONAPI::Serializer',
                       '',
                       '# TODO: the attributes this resource exposes',
                       '# attributes :name'])
      end

      # --- routes ---

      def route_line
        "resources :#{resource.pluralize}, only: %i[#{file_name}], param: :uuid"
      end

      # --- specs ---

      def request_spec
        pending_spec("'#{request_method} #{resource_path}'", 'testing-rails-requests',
                     ['success (201/200 + serialized payload)',
                      'validation failure (422 + errors)',
                      'authentication required'])
      end

      def routing_spec
        pending_spec("#{api_module}::#{controller_class}", 'testing-routing',
                     ["routes #{request_method} #{resource_path}"])
      end

      def request_method
        { 'create' => 'POST', 'update' => 'PATCH', 'destroy' => 'DELETE' }.fetch(file_name, 'POST')
      end

      def resource_path
        "/#{resource.pluralize}"
      end

      def resource
        (class_path.last || file_name).singularize
      end
    end
  end
end
