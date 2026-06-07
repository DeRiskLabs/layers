# frozen_string_literal: true

module UserStories
  module Widgets
    class Register < ApplicationUserStory
      required :name

      emits success: [:widget], failure: [:errors]

      observer :announce, of_event: :success

      instrument Instrumenters::RecordingInstrumenter

      def call
        UseCases::Widgets::Create.call(
          name: name,
          listener: self,
          on_success: :widget_created,
          on_failure: :widget_failed,
        )
      end

      def widget_created(widget:)
        success(widget: widget)
      end

      def widget_failed(errors: nil)
        failure(errors: errors)
      end

      private

      def announce
        $acceptance_events << :announced if $acceptance_events
        Rails.logger.info('widget registered')
      end
    end
  end
end
