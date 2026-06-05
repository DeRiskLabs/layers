# frozen_string_literal: true

module Layers
  module BaseJob
    class InvalidUseCase < Layers::Error; end
    class JobFailed < Layers::Error; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def use_case(name_string)
        fail ArgumentError, 'use_case argument must be a string' unless name_string.is_a?(String)

        @use_case_class_name = name_string.camelize
      end

      def use_case_class_name
        @use_case_class_name
      end

      def fire_and_forget
        @fire_and_forget = true
      end

      def fire_and_forget?
        !!@fire_and_forget
      end
    end

    def perform(**perform_args)
      call_use_case(**perform_args)
    end

    def success(**return_args)
      on_success(**return_args)
    end

    def failure(**return_args)
      on_failure(**return_args)
    end

    def on_success(**_args); end

    def on_failure(**args)
      fail JobFailed, failed_message(args)
    end


    private

    def call_use_case(**args)
      use_case.call(
        listener: job_listener,
        on_success: :success,
        on_failure: :failure,
        **args,
      )
    end

    def job_listener
      self.class.fire_and_forget? ? nil : self
    end

    def use_case
      class_name = self.class.use_case_class_name || fail(InvalidUseCase)
      class_name.constantize
    rescue NameError
      raise InvalidUseCase, "Use case name '#{class_name}' did not constantize."
    end

    def failed_message(args)
      messages = failure_messages(args)
      return "#{self.class.use_case_class_name} failed" if messages.empty?

      "#{self.class.use_case_class_name} failed: #{messages.join('; ')}"
    end

    def failure_messages(args)
      args.values.flat_map { |value| extracted_errors(value) }
    end

    def extracted_errors(value)
      errors = value.respond_to?(:errors) ? value.errors : value
      return errors.full_messages if errors.respond_to?(:full_messages)

      Array(errors).map(&:to_s)
    end
  end
end
