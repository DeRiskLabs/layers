# frozen_string_literal: true

require 'logger'

module Layers

  module DSL

    # The Observers module provides functionality for registering and notifying
    # observer methods when specific events occur.
    #
    # This module implements the Observer pattern, allowing classes to register
    # methods that should be called when success or failure events occur,
    # without tightly coupling the event source to its observers.
    module Observers

      def self.included(base)
        base.extend ClassMethods
      end

      # Class methods added to the including class
      #
      # Provides methods for registering observer methods and configuring
      # exception handling for observer notifications.
      module ClassMethods

        attr_reader :observer_exception_handler_method

        def observer(*observer_methods, of_event: :success)
          observer_methods.each do |observer|
            observers[of_event] ||= Set.new
            observers[of_event] << observer
          end
        end

        def observers
          @observers ||= {}
        end

        def observer_exception_handler(exception_handler_method_name)
          @observer_exception_handler_method = exception_handler_method_name
        end

      end

      # Instance methods included

      def notify_observers(of_event: :success)
        observers_array(of_event: of_event).each { |observer| safely_invoke_observer(observer) }
      rescue StandardError => e
        handle_observer_exception(e)
      end

      def observers
        @observers ||= self.class.observers
      end


      private

      def exception_handler_method
        self.class.observer_exception_handler_method
      end

      def handle_observer_exception(exception)
        send exception_handler_method, exception if exception_handler_method

        logger.warn "#{self.class} observers failed with #{exception.message}"
        logger.debug exception.backtrace&.join("\n")
      end

      def logger
        @logger ||= Layers::Logger.logger
      end

      def observers_array(of_event: :success)
        Array(observers[of_event]).compact
      end

      def safely_invoke_observer(observer)
        if observer.respond_to?(:call)
          observer.call
        else
          send observer
        end
      end

    end

  end

end
