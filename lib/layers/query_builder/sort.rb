# frozen_string_literal: true

module Layers

  module QueryBuilder

    # The Sort module provides chainable ordering for query objects, defaulting
    # to newest-first by created_at.
    module Sort

      def order(sort_field: :created_at, sort_direction: :desc)
        @relation = relation.order(sort_field => sort_direction)
        self
      end

    end

  end

end
