# frozen_string_literal: true

module UseCases
  module Widgets
    class Create < ApplicationUseCase
      required :name

      emits success: [:widget], failure: [:errors]

      def call
        widget = nil
        ActiveRecord::Base.transaction do
          widget = Widget.create!(name: name)
        end
        success(widget: widget)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
