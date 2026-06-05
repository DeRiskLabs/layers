# frozen_string_literal: true

module RuboCop
  module Cop
    module Layers
      class UserStoryOutsideAdapter < Base
        include UserStoryReference

        MSG = 'Only delivery adapters (user interaction points) call user stories.'

        DEFAULT_ALLOWED_PATHS = [
          '/controllers/',
          '/graphql/',
          '/user_stories/',
          '/spec/',
          '/test/',
        ].freeze

        def on_const(node)
          return unless user_stories_root?(node)
          return if allowed_file?

          add_offense(node)
        end


        private

        def allowed_file?
          path = processed_source.file_path.to_s
          allowed_paths.any? { |allowed| path.include?(allowed) }
        end

        def allowed_paths
          cop_config.fetch('AllowedPaths', DEFAULT_ALLOWED_PATHS)
        end
      end
    end
  end
end
