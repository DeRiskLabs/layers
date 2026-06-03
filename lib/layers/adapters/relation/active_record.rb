# frozen_string_literal: true

module Layers
  module Adapters
    module Relation
      class ActiveRecord

        def self.relation?(object)
          return true if object.is_a?(Class)
          return false unless defined?(::ActiveRecord::Relation)

          object.is_a?(::ActiveRecord::Relation)
        end

      end
    end
  end
end
