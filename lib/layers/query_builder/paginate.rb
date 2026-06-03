# frozen_string_literal: true

module Layers
  module QueryBuilder
    class PaginationError < Layers::Error; end

    module Paginate

      def page(page)
        @paginated = true
        @relation = relation.page(page)
        self
      end

      def paginated
        @paginated
      end

      def per(size)
        if paginated
          @relation = relation.per_page(size)
          self
        else
          error = 'Cannot set page size on an unpaginated query.'
          fail PaginationError, error
        end
      end

    end
  end
end
