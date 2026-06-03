# frozen_string_literal: true

require 'naught'

module Layers

  module DSL

    # The NullListener module provides a null object implementation for listeners
    # in the Layers pattern.
    #
    # This module allows classes to have a default listener that does nothing
    # when no explicit listener is provided, following the Null Object pattern.
    # This eliminates the need for nil checks when calling listener methods.
    module NullListener


      private

      def null_listener
        @null_listener ||= null_listener_factory.new
      end

      def null_listener_factory
        @null_listener_factory ||= Naught.build(&:black_hole)
      end

    end

  end

end
