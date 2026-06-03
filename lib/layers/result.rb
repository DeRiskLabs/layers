# frozen_string_literal: true

module Layers

  # Result is a simple value object that represents the outcome of an operation.
  # It can be either a success or a failure, and it can contain a value or errors.
  class Result

    attr_reader :success, :value, :errors, :metadata

    # Create a new success result with an optional value and metadata
    #
    # @param value [Object] the value to be returned
    # @param metadata [Hash] additional metadata about the operation
    # @return [Result] a success result
    def self.success(value = nil, metadata = {})
      new(success: true, value: value, metadata: metadata)
    end

    # Create a new failure result with optional errors and metadata
    #
    # @param errors [Array, String, Exception, Object] the error(s) that occurred
    # @param metadata [Hash] additional metadata about the operation
    # @return [Result] a failure result
    def self.failure(errors = nil, metadata = {})
      new(success: false, errors: errors, metadata: metadata)
    end

    # Initialize a new Result
    #
    # @param success [Boolean] whether the operation was successful
    # @param value [Object] the value to be returned (for success)
    # @param errors [Array, String, Exception, Object] the error(s) that occurred (for failure)
    # @param metadata [Hash] additional metadata about the operation
    def initialize(success:, value: nil, errors: nil, metadata: {})
      @success = success
      @value = value
      @errors = normalize_errors(errors)
      @metadata = metadata
    end

    # Check if the result is a success
    #
    # @return [Boolean] true if the result is a success
    def success?
      @success
    end

    # Check if the result is a failure
    #
    # @return [Boolean] true if the result is a failure
    def failure?
      !@success
    end

    # Execute the given block if the result is a success, passing the value
    # Returns a new Result based on the block's return value
    #
    # @yield [value] the value of the result
    # @return [Result] a new result based on the block's return value
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

    # Execute the given block if the result is a success, passing the value
    # Returns self to allow for method chaining
    #
    # @yield [value] the value of the result
    # @return [Result] self
    def on_success
      yield(value) if success?
      self
    end

    # Execute the given block if the result is a failure, passing the errors
    # Returns self to allow for method chaining
    #
    # @yield [errors] the errors of the result
    # @return [Result] self
    def on_failure
      yield(errors) if failure?
      self
    end

    # Convert the result to a hash
    #
    # @return [Hash] a hash representation of the result
    def to_h
      if success?
        { success: true, value: value, metadata: metadata }
      else
        { success: false, errors: errors, metadata: metadata }
      end
    end


    private

    # Normalize errors to an array
    #
    # @param errors [Array, String, Exception, Object] the error(s) to normalize
    # @return [Array] an array of errors
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
    # rubocop:enable Lint/DuplicateBranch

  end

end
