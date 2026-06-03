# frozen_string_literal: true

module Layers
  module Adapters
    module Pagination
      class WillPaginate

        def self.page(relation, number)
          relation.page(number)
        end

        def self.per(relation, size)
          relation.per_page(size)
        end

      end
    end
  end
end
