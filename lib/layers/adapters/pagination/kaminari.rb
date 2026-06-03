# frozen_string_literal: true

module Layers
  module Adapters
    module Pagination
      class Kaminari

        def self.page(relation, number)
          relation.page(number)
        end

        def self.per(relation, size)
          relation.per(size)
        end

      end
    end
  end
end
