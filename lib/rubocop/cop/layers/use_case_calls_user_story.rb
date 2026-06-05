# frozen_string_literal: true

module RuboCop
  module Cop
    module Layers
      class UseCaseCallsUserStory < Base
        include UserStoryReference

        MSG = 'A use case never calls a user story — user interaction boundary to ' \
              'business logic, never the reverse.'

        def on_const(node)
          return unless user_stories_root?(node)
          return unless use_case_file?

          add_offense(node)
        end


        private

        def use_case_file?
          processed_source.file_path.to_s.include?('/use_cases/')
        end
      end
    end
  end
end
