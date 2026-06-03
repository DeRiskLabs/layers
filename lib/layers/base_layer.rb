# frozen_string_literal: true

# The Layers module is the main namespace for the Layers gem.
# It provides a framework for implementing layered architecture in Ruby applications.
module Layers

  # BaseLayer is the core class of the Layers gem, providing the foundation for
  # implementing the layered architecture pattern.
  #
  # This class combines several DSL modules to provide a comprehensive set of
  # features for creating service objects, use cases, and user stories:
  # - Observer pattern for side effects
  # - Input validation and handling
  # - Null listener pattern for safe callback handling
  # - Default callbacks for standardized success/failure handling
  # - Class callable pattern for convenient instantiation and execution
  #
  # BaseLayer objects follow a consistent lifecycle:
  # 1. Instantiate with required and optional inputs
  # 2. Execute business logic in the #call method
  # 3. Return success or failure, notifying observers and calling listener callbacks
  class BaseLayer

    include Layers::DSL::Observers
    include Layers::DSL::Inputs
    include Layers::DSL::NullListener
    include Layers::DSL::CallbackDefaults
    include Layers::DSL::ClassCallable

    attr_reader :listener,
                :on_failure,
                :on_success,
                :failed,
                :succeeded,
                :result

    def initialize(listener: nil, on_failure: nil, on_success: nil, **opts)
      @listener = listener || null_listener
      @on_failure = on_failure || self.class.on_failure_default
      @on_success = on_success || self.class.on_success_default

      super(opts)
    end

    def failure?
      @failed
    end

    def success?
      @succeeded
    end

    private

    def failure(*failure_args, **failure_opts)
      @failed = true

      @result = failure_opts.tap do |opts|
        opts.merge(failure_args: failure_args) unless failure_args.empty?
      end

      notify_observers(of_event: :failure)
      listener.public_send(on_failure, *failure_args, **failure_opts)
    end

    def success(*success_args, **success_opts)
      @succeeded = true

      @result = success_opts.tap do |opts|
        opts.merge(success_args: success_args) unless success_args.empty?
      end

      notify_observers(of_event: :success)
      listener.public_send(on_success, *success_args, **success_opts)
    end
  end
end
