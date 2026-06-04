# frozen_string_literal: true

module Layers

  # Result is a simple value object that represents the outcome of an operation.
  # It can be either a success or a failure, and it can contain a value or errors.
  class Result

    attr_reader :success, :value, :errors, :metadata

    def self.success(value = nil, metadata = {})
      new(success: true, value: value, metadata: metadata)
    end

    def self.failure(errors = nil, metadata = {})
      new(success: false, errors: errors, metadata: metadata)
    end

    def initialize(success:, value: nil, errors: nil, metadata: {})
      @success = success
      @value = value
      @errors = normalize_errors(errors)
      @metadata = metadata
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def and_then
      return self if failure?

      begin
        result = yield(value)
        return result if result.is_a?(Result)

        Result.success(result, metadata)
      rescue StandardError => e
        Result.failure(e, metadata.merge(exception: e.class.name))
      end
    end

    def on_success
      yield(value) if success?
      self
    end

    def on_failure
      yield(errors) if failure?
      self
    end

    def to_h
      if success?
        { success: true, value: value, metadata: metadata }
      else
        { success: false, errors: errors, metadata: metadata }
      end
    end


    private

    def normalize_errors(errors)
      case errors
      when nil
        []
      when Array
        errors
      when String
        [errors]
      when Exception
        ["#{errors.class}: #{errors.message}"]
      else
        [errors]
      end
    end

  end

end
