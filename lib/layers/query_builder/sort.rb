# frozen_string_literal: true

module Layers
  module QueryBuilder
    module Sort
      def order(sort_field: :created_at, sort_direction: :desc)
        @relation = relation.order(sort_field => sort_direction)
        self
      end
    end
  end
end
