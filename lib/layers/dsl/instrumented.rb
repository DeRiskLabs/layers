# frozen_string_literal: true

module Layers

  module DSL

    # The instrument macro: declared instrumenter classes are inserted between
    # the layer and its listener as a callback daisy chain.
    module Instrumented

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def instrument(*instrumenter_classes)
          instrumenter_classes.each do |instrumenter_class|
            unless instrumenter_class.is_a?(Class)
              fail ArgumentError, 'instrument expects instrumenter classes'
            end
            instrumenters << instrumenter_class
          end
        end

        def instrumenters
          @instrumenters ||= Set.new
        end

      end


      private

      def insert_instrumenters!
        self.class.instrumenters.reverse_each do |instrumenter_class|
          @listener = instrumenter_class.new(
            subject: self,
            listener: @listener,
            on_failure: @on_failure,
            on_success: @on_success,
          )
          @on_failure = :failure
          @on_success = :success
        end
      end

    end

  end

end
