# frozen_string_literal: true

module Layers
  module Adapters
    module Relation
      class DuckType
        def self.relation?(object)
          object.respond_to?(:where)
        end
      end
    end
  end
end
