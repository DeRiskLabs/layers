# frozen_string_literal: true

module Layers

  module DSL

    # Makes a class callable directly: .call creates an instance and invokes #call.
    module ClassCallable

      class MissingMethodError < StandardError

        def initialize(original_error, klass_name)
          method_name = original_error.cause.name
          error_location = original_error.backtrace.first

          message = "The method '#{method_name}' is not defined. " \
                    'Check delegations as this is a common cause. ' \
                    "The class this occurred in is '#{klass_name}'. " \
                    "Location: '#{error_location}'."
          super(message)
        end

      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def call(*args, **opts)
          new(*args, **opts).call
        rescue TypeError => e
          raise MissingMethodError.new(e, name) if e.cause.is_a?(NameError)

          raise e
        end

      end

      def call
        fail NotImplementedError
      end

    end

  end

end
