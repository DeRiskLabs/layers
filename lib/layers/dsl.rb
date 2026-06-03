# frozen_string_literal: true

require 'layers/dsl/callback_defaults'
require 'layers/dsl/class_callable'
require 'layers/dsl/inputs'
require 'layers/dsl/null_listener'
require 'layers/dsl/observers'

module Layers

  module DSL

    class MissingRequiredInputs < ArgumentError; end
    class UnexpectedInputs < ArgumentError; end

    class NotImplementedError < NotImplementedError; end

  end

end
