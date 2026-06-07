# frozen_string_literal: true

module Queries
  class WidgetsQuery < ApplicationQuery
    relation_class 'Widget'

    private

    def build_relation_defaults!
      @relation = relation.where.not(name: nil)
    end
  end
end
