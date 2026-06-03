# frozen_string_literal: true

module Layers
  module QueryBuilder
    class PaginationError < Layers::Error; end

    module Paginate

      def page(page)
        @paginated = true
        @relation = pagination_adapter.page(relation, page)
        self
      end

      def paginated
        @paginated
      end

      def per(size)
        if paginated
          @relation = pagination_adapter.per(relation, size)
          self
        else
          error = 'Cannot set page size on an unpaginated query.'
          fail PaginationError, error
        end
      end


      private

      def pagination_adapter
        Layers.configuration.pagination_adapter
      end

    end
  end
end
