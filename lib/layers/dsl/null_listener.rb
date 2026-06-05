# frozen_string_literal: true

require 'naught'

module Layers
  module DSL
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
