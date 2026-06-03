# frozen_string_literal: true

module Layers

  module QueryBuilder

    class ConfigurationError < Layers::Error; end

    # The RelationDefaults module lets a query object declare the model that
    # provides its initial relation.
    #
    # The relation_class DSL takes a name (camelized and constantized) or a
    # callable returning the class name, and default_initial_relation resolves
    # it when no explicit relation is given at construction.
    module RelationDefaults

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods added to the including class
      #
      # Provides the relation_class declaration and resolves the declared name
      # to the model class.
      module ClassMethods

        def default_relation_class
          return unless default_relation_class_name
          default_relation_class_name.constantize
        rescue NameError
          error = 'Default relation_class must constantizable to a model name.'
          raise ConfigurationError, error
        end

        def default_relation_class_name
          @default_relation_class_name
        end

        def relation_class(name_finder)
          name = if name_finder.respond_to?(:call)
                   name_finder.call
                 else
                   name_finder.to_s.camelize
                 end
          @default_relation_class_name = name
        end

      end


      def default_initial_relation
        self.class.default_relation_class
      end

    end

  end

end
