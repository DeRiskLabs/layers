# frozen_string_literal: true

require 'logger'
require 'singleton'

module Layers

  # Extends ::Logger as a singleton; uses Rails.logger in a Rails environment
  # or its own log file.
  class Logger < ::Logger

    include Singleton

    class << self

      def logger
        @logger ||= if Layers.configuration&.logger
                      Layers.configuration.logger
                    elsif defined?(Rails) && !Rails.env.production? && Rails.logger
                      Rails.logger
                    else
                      Layers::Logger.instance
                    end
      end

    end

    def initialize
      if defined?(Rails)
        super(Rails.root.join('log/layers.log'))
      else
        super(File.open('log/layers.log', 'a'))
      end
    end

  end

end
