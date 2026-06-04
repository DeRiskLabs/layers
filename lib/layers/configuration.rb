# frozen_string_literal: true

module Layers

  # Global gem settings: logger, graphql_execution_error, error masking,
  # pagination and relation adapters.
  class Configuration

    attr_accessor :logger,
                  :reveal_masked_errors
    attr_writer :exposed_error_classes,
                :graphql_execution_error,
                :masked_error_message,
                :pagination_adapter,
                :relation_adapter

    def exposed_error_classes
      @exposed_error_classes ||= []
    end

    def graphql_execution_error
      @graphql_execution_error ||= detect_graphql_execution_error
    end

    def masked_error_message
      @masked_error_message ||= 'Internal error'
    end

    def pagination_adapter
      @pagination_adapter ||= detect_pagination_adapter
    end

    def relation_adapter
      @relation_adapter ||= Adapters::Relation::ActiveRecord
    end


    private

    def detect_graphql_execution_error
      return unless defined?(::GraphQL::ExecutionError)

      ::GraphQL::ExecutionError
    end

    def detect_pagination_adapter
      return Adapters::Pagination::Kaminari if defined?(::Kaminari)

      Adapters::Pagination::WillPaginate
    end

  end

  class << self

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

  end

end
