# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Instrumenter do
  subject(:instrumenter) do
    instrumenter_class.new(
      subject: layer,
      listener: listener,
      on_failure: :create_failed,
      on_success: :create_succeeded,
    )
  end

  let(:instrumenter_class) { described_class }
  let(:layer) { double('Layer') }
  let(:listener) { spy('Listener') }
  let(:logger) { instance_spy(Logger) }

  before do
    allow(Layers::Logger).to receive(:logger).and_return(logger)
  end

  describe '#success' do
    execute do
      instrumenter.success('extra', seller: :seller)
    end

    it 'forwards to the listener with the original callback name' do
      expect(listener).to have_received(:create_succeeded).with('extra', seller: :seller)
    end

    it 'logs the default instrumentation line' do
      expect(logger).to have_received(:info).with(/success in \d+(\.\d+)?ms/)
    end
  end

  describe '#failure' do
    execute do
      instrumenter.failure(error: 'boom')
    end

    it 'forwards to the listener with the original callback name' do
      expect(listener).to have_received(:create_failed).with(error: 'boom')
    end

    it 'logs the default instrumentation line' do
      expect(logger).to have_received(:info).with(/failure in \d+(\.\d+)?ms/)
    end
  end

  describe '#instrument!' do
    context 'with a custom instrumenter' do
      let(:recordings) { [] }

      let(:instrumenter_class) do
        recorder = recordings
        Class.new(described_class) do
          define_method(:instrument!) do |outcome|
            recorder << [outcome, subject, outcome_opts]
          end
        end
      end

      execute do
        instrumenter.success(seller: :seller)
      end

      it 'receives the outcome' do
        expect(recordings.first[0]).to be(:success)
      end

      it 'exposes the instrumented subject' do
        expect(recordings.first[1]).to be(layer)
      end

      it 'exposes the outcome payload' do
        expect(recordings.first[2]).to eq(seller: :seller)
      end
    end

    context 'when the instrumenter raises' do
      let(:instrumenter_class) do
        Class.new(described_class) do
          def instrument!(_outcome)
            fail 'instrumentation broke'
          end
        end
      end

      it 'propagates the error' do
        expect do
          instrumenter.success
        end.to raise_error('instrumentation broke')
      end

      context 'with the error suppressed' do
        execute do
          instrumenter.success
        rescue RuntimeError
          nil
        end

        it 'never calls the listener' do
          expect(listener).not_to have_received(:create_succeeded)
        end
      end
    end
  end
end
