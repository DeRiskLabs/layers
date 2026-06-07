# frozen_string_literal: true

require 'active_model'

module Layers
  class BaseForm
    include ActiveModel::Model

    attr_writer :persisted

    def form_error_messages
      errors.select do |error|
        report_full_errors_for.include? error.attribute
      end.map(&:full_message).compact.reject(&:empty?)
    end

    def new_record?
      !persisted?
    end

    def persisted?
      @persisted ||= false
    end


    private

    def report_full_errors_for
      []
    end
  end
end
