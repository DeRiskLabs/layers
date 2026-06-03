# frozen_string_literal: true

module Layers
  class BaseQueryObject
    class RelationError < Layers::Error; end

    include Layers::QueryBuilder::RelationDefaults
    include Layers::QueryBuilder::Paginate
    include Layers::QueryBuilder::Sort


    attr_reader :options,
                :relation,
                :unscoped_relation

    delegate :all,
             :count,
             :find,
             :find_by,
             :find_by!,
             :first,
             :includes,
             :joins,
             :last,
             :left_joins,
             :limit,
             :none,
             :offset,
             :pluck,
             :select,
             :where,
             to: :relation

    def initialize(relation = nil, **options)
      @options = options
      @relation = options[:relation] || relation || default_initial_relation
      @unscoped_relation = @relation

      validate_relation!
      build_relation_defaults!
    end


    private

    def validate_relation!
      return if relation.is_a?(ActiveRecord::Relation) || relation.is_a?(Class)
      fail RelationError, 'Relation must duck-type to an ActiveRecord::Relation'
    end

    def build_relation_defaults!
      fail NotImplementedError
    end

  end
end
