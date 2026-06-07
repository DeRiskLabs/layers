# frozen_string_literal: true

module Instrumenters
  class RecordingInstrumenter < Layers::Instrumenter
    private

    def instrument!(outcome)
      $acceptance_events << [:instrumented, outcome] if $acceptance_events
    end
  end
end
