# frozen_string_literal: true

require 'active_support/core_ext/enumerable'

module Layers

  module DSL

    # The Inputs module provides functionality for declaring and validating
    # required and optional inputs for a class.
    #
    # This module allows classes to define which inputs are required and which
    # are optional, and provides validation to ensure all required inputs are
    # provided and no unexpected inputs are passed.
    module Inputs

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods added to the including class
      #
      # Provides methods for declaring required and optional inputs,
      # as well as default values for optional inputs.
      module ClassMethods

        def all_inputs
          optional_inputs | required_inputs
        end

        def optional(*input_names)
          input_names.each do |input_name|
            optional_inputs << input_name
            attr_accessor input_name
          end
        end

        def optional_inputs
          @optional_inputs ||= Set.new
        end

        def required(*input_names)
          input_names.each do |input_name|
            required_inputs << input_name
            attr_accessor input_name
          end
        end

        def required_inputs
          @required_inputs ||= Set.new
        end

        def optional_with_default(**defaults_hash)
          defaults_hash.each do |attr_name, value|
            optional(attr_name)
            default_inputs[attr_name] = value
          end
        end

        def default_inputs
          @default_inputs ||= {}
        end

      end

      attr_accessor :inputs

      def initialize(inputs = {})
        @inputs = inputs

        validate_required_inputs_present!
        validate_no_unpermitted_inputs!

        add_default_inputs!
        set_attributes_from_inputs!
      end

      def attributes
        @attributes ||= required_attributes.merge optional_attributes
      end

      def optional_attributes
        @optional_attributes ||= self.class.optional_inputs.index_with do |input|
          public_send(input)
        end
      end

      def required_attributes
        @required_attributes ||= self.class.required_inputs.index_with do |input|
          public_send(input)
        end
      end

      private

      def add_default_inputs!
        default_inputs.each { |attr, value| inputs[attr] = value unless inputs.key?(attr) }
      end

      def default_inputs
        self.class.default_inputs
      end

      def extra_inputs
        @extra_inputs ||= received_inputs - Array(self.class.all_inputs)
      end

      def missing_inputs
        @missing_inputs ||= Array(self.class.required_inputs) - received_inputs
      end

      def received_inputs
        @received_inputs ||= inputs.keys
      end

      def set_attributes_from_inputs!
        inputs.each { |attr, value| public_send("#{attr}=", value) }
      end

      # Input Presence Validation

      def validate_required_inputs_present!
        return if missing_inputs.empty?

        raise Layers::DSL::MissingRequiredInputs,
              "Missing required inputs: #{missing_inputs.join(', ')}"
      end

      def validate_no_unpermitted_inputs!
        return if extra_inputs.empty?

        raise Layers::DSL::UnexpectedInputs,
              "Undeclared inputs: #{extra_inputs.join(', ')}"
      end

    end

  end

end
