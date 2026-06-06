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

        def definition_name?(node)
          outermost = node
          outermost = outermost.parent while outermost.parent&.const_type?
          parent = outermost.parent
          return false unless parent&.module_type? || parent&.class_type?

          parent.identifier.equal?(outermost)
        end
      end
    end
  end
end
