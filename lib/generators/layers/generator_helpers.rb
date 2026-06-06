# frozen_string_literal: true

module Layers
  module Generators
    module GeneratorHelpers


      private

      def namespaced(root, declaration, body)
        namespaced_in([*root.split('::'), *class_path.map(&:camelize)], declaration, body)
      end

      def namespaced_in(modules, declaration, body)
        lines = ['# frozen_string_literal: true', '']
        lines.concat(opening_lines(modules))
        lines.concat(declaration_lines(declaration, body, modules.size))
        lines.concat(closing_lines(modules.size))
        "#{lines.join("\n")}\n"
      end

      def opening_lines(modules)
        modules.each_with_index.map { |mod, index| "#{'  ' * index}module #{mod}" }
      end

      def declaration_lines(declaration, body, depth)
        ["#{'  ' * depth}#{declaration}",
         *body.map { |line| line.empty? ? '' : "#{'  ' * (depth + 1)}#{line}" },
         "#{'  ' * depth}end"]
      end

      def closing_lines(depth)
        (depth - 1).downto(0).map { |index| "#{'  ' * index}end" }
      end

      def pending_spec(described, testing_skill)
        <<~RUBY
          # frozen_string_literal: true

          require 'rails_helper'

          RSpec.describe #{described} do
            pending "specs for #{described} (follow #{testing_skill})"
          end
        RUBY
      end
    end
  end
end
