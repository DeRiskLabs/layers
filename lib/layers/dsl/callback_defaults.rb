# frozen_string_literal: true

module Layers
  module DSL
    module CallbackDefaults
      ON_FAILURE_DEFAULT_CALLBACK = :on_failure
      ON_SUCCESS_DEFAULT_CALLBACK = :on_success

      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      module ClassMethods
        def default_callbacks(**args)
          @on_failure_default = args[:on_failure]
          @on_success_default = args[:on_success]
        end

        def on_failure_default
          @on_failure_default || ON_FAILURE_DEFAULT_CALLBACK
        end

        def on_success_default
          @on_success_default || ON_SUCCESS_DEFAULT_CALLBACK
        end
      end

      module InstanceMethods
        attr_reader :on_failure_default, :on_success_default

        def initialize(*args, **opts)
          @on_failure_default = self.class.on_failure_default
          @on_success_default = self.class.on_success_default

          super
        end
      end
    end
  end
end
