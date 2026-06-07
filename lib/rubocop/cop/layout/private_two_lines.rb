# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module RuboCop
  module Cop
    module Layout
      class PrivateTwoLines < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Must have exactly two blank lines before private'

        def on_send(node)
          return unless node.method?(:private)

          previous_line = node.first_line - 1
          blank_lines = count_blank_lines_before(processed_source, previous_line)

          return if blank_lines == 2

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end


        private

        def autocorrect(corrector, node)
          range = range_between(
            find_last_code_line(processed_source, node.first_line - 1),
            node.source_range.begin_pos,
          )

          corrector.replace(range, "\n\n\n")
        end

        def count_blank_lines_before(processed_source, line)
          count = 0
          line.downto(1) do |current_line|
            break unless processed_source[current_line - 1].blank?
            count += 1
          end
          count
        end

        def find_last_code_line(processed_source, line)
          line.downto(1) do |current_line|
            line_content = processed_source[current_line - 1]
            next if line_content.blank?

            # Calculate position based on line number and content length
            previous_lines_length = processed_source[0..current_line - 2].join("\n").length
            return previous_lines_length + line_content.length + 1
          end
          0
        end
      end
    end
  end
end
