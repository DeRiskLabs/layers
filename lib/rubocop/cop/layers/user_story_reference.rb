# frozen_string_literal: true

module RuboCop
  module Cop
    module Layers
      module UserStoryReference


        private

        def user_stories_root?(node)
          namespace = node.children.first
          (namespace.nil? || namespace.cbase_type?) && node.children[1] == :UserStories
        end
      end
    end
  end
end
