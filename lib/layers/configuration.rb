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
