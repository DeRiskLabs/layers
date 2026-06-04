# frozen_string_literal: true

require 'logger'
require 'singleton'

module Layers

  # Resolves to the configured logger, Rails.logger when present, or its own
  # $stdout singleton.
  class Logger < ::Logger

    include Singleton

    class << self

      def logger
        @logger ||= Layers.configuration.logger || rails_logger || instance
      end


      private

      def rails_logger
        return unless defined?(Rails)

        Rails.logger
      end

    end

    def initialize
      super($stdout)
    end

  end

end
