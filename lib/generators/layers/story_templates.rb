# frozen_string_literal: true

module Layers
  module Generators
    module StoryTemplates


      private

      def story_body
        [*story_contract_section, '', *story_call_section, '', *story_callback_section,
         '', '', 'private', '', *story_use_case_section]
      end

      def story_contract_section
        ['required :current_authorization # TODO: declare the inputs this story receives',
         '',
         "emits success: [:#{resource}], failure: [:errors] # TODO: declare the real payloads"]
      end

      def story_call_section
        ['def call',
         '  use_case.call(**use_case_args)',
         'end']
      end

      def story_callback_section
        ["def #{file_name}_succeeded(form:)",
         "  success(#{resource}: nil) # TODO: emit the named object the interaction produces",
         'end',
         '',
         "def #{file_name}_failed(form: nil, errors: nil)",
         '  failure(errors: errors || form.errors)',
         'end']
      end

      def story_use_case_section
        ['def use_case',
         "  #{use_case_constant}",
         'end',
         '',
         *story_use_case_args_section,
         '',
         'def use_case_options',
         '  {} # TODO: the raw inputs the use case requires (e.g. name:, email:)',
         'end']
      end

      def story_use_case_args_section
        ['def use_case_args',
         '  {',
         '    listener: self,',
         "    on_success: :#{file_name}_succeeded,",
         "    on_failure: :#{file_name}_failed,",
         '    **use_case_options,',
         '  }',
         'end']
      end

      def resource
        (class_path.last || file_name).singularize
      end

      def use_case_constant
        ['UseCases', *class_path.map(&:camelize), file_name.camelize].join('::')
      end
    end
  end
end
