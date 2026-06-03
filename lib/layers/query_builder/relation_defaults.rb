module Layers
  module QueryBuilder
    class ConfigurationError < Layers::Error; end

    module RelationDefaults
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def default_relation_class
          return unless default_relation_class_name
          default_relation_class_name.constantize
        rescue NameError
          error = 'Default relation_class must constantizable to a model name.'
          fail ConfigurationError, error
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
