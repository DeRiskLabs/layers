# frozen_string_literal: true

require 'naught'

module Layers

  module DSL

    # A do-nothing default listener (Null Object) used when no listener is provided.
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
