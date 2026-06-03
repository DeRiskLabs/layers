# frozen_string_literal: true

# The Layers module is the main namespace for the Layers gem.
# It provides a framework for implementing layered architecture in Ruby applications.
module Layers

  # Configuration class for the Layers gem.
  #
  # This class allows configuring global settings for the Layers gem,
  # such as the logger to use for logging events and errors.
  class Configuration

    attr_accessor :logger
    attr_writer :graphql_execution_error,
                :pagination_adapter,
                :relation_adapter

    def graphql_execution_error
      @graphql_execution_error ||= detect_graphql_execution_error
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
