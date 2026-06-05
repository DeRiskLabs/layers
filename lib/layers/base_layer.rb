# frozen_string_literal: true

module Layers
  class BaseLayer
    include Layers::DSL::Observers
    include Layers::DSL::Inputs
    include Layers::DSL::NullListener
    include Layers::DSL::CallbackDefaults
    include Layers::DSL::ClassCallable
    include Layers::DSL::Instrumented
    include Layers::DSL::Emits

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

      verify_listener_contract!
      insert_instrumenters!

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
      validate_emitted!(:failure, failure_opts)
      @failed = true
      @result = result_payload(failure_opts, failure_args, key: :failure_args)

      notify_observers(of_event: :failure)
      listener.public_send(on_failure, *failure_args, **failure_opts)
    end

    def success(*success_args, **success_opts)
      validate_emitted!(:success, success_opts)
      @succeeded = true
      @result = result_payload(success_opts, success_args, key: :success_args)

      notify_observers(of_event: :success)
      listener.public_send(on_success, *success_args, **success_opts)
    end

    def result_payload(opts, args, key:)
      return opts if args.empty?

      opts.merge(key => args)
    end
  end
end
