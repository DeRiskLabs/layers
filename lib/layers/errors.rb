# frozen_string_literal: true

module Layers
  class Error < StandardError; end
  class ConfigurationError < Layers::Error; end
  class ContractViolation < Layers::Error; end
end
