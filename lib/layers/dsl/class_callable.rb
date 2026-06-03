# frozen_string_literal: true

module Layers

  module DSL

    # The ClassCallable module provides functionality for making a class callable
    # directly, allowing instances to be created and their #call method invoked
    # in a single step.
    #
    # This pattern is useful for creating service objects or command objects
    # that perform a single operation and return a result.
    module ClassCallable

      # Error raised when a method is missing during the execution of a callable class
      #
      # Provides more helpful error messages when a method is missing, particularly
      # when the error is related to a delegation.
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

      # Class methods added to the including class
      #
      # Provides the .call class method that creates an instance and calls
      # its #call method, handling any method-related errors that occur.
      module ClassMethods

        def call(*args, **opts)
          new(*args, **opts).call
        rescue TypeError => e
          raise MissingMethodError.new(e, name) if e.cause.is_a?(NameError)

          raise e
        end

      end

      # Enforce the implementation of the call method

      def call
        fail NotImplementedError
      end

    end

  end

end
