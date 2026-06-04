# frozen_string_literal: true

module Layers

  # Decorates the listener chain: receives the subject's success/failure,
  # runs #instrument!, then forwards the callback to the next listener.
  class Instrumenter

    attr_reader :subject,
                :listener,
                :on_failure,
                :on_success,
                :outcome_args,
                :outcome_opts,
                :started_at

    def initialize(subject:, listener:, on_failure:, on_success:)
      @subject = subject
      @listener = listener
      @on_failure = on_failure
      @on_success = on_success
      @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def success(*success_args, **success_opts)
      capture(success_args, success_opts)
      instrument!(:success)
      listener.public_send(on_success, *success_args, **success_opts)
    end

    def failure(*failure_args, **failure_opts)
      capture(failure_args, failure_opts)
      instrument!(:failure)
      listener.public_send(on_failure, *failure_args, **failure_opts)
    end


    private

    def capture(args, opts)
      @outcome_args = args
      @outcome_opts = opts
    end

    def elapsed_ms
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(1)
    end

    def instrument!(outcome)
      logger.info "#{subject.class} #{outcome} in #{elapsed_ms}ms"
    end

    def logger
      @logger ||= Layers::Logger.logger
    end

  end

end
