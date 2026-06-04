# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::BaseLayer do
  it { expect(described_class.included_modules).to include(Layers::DSL::Observers) }
  it { expect(described_class.included_modules).to include(Layers::DSL::Inputs) }
  it { expect(described_class.included_modules).to include(Layers::DSL::NullListener) }
  it { expect(described_class.included_modules).to include(Layers::DSL::CallbackDefaults) }
  it { expect(described_class.included_modules).to include(Layers::DSL::ClassCallable) }
  it { expect(described_class.included_modules).to include(Layers::DSL::Instrumented) }

  describe '#initialize' do
    subject(:layer) { described_class.allocate }

    let(:init_args) { {} }

    execute do
      layer.send(:initialize, **init_args)
    end

    context 'with no arguments' do
      it 'sets the null listener' do
        expect(layer.listener).to be_a(Naught::BasicObject)
      end

      it 'sets the default failure callback' do
        expect(layer.on_failure).to eq(layer.on_failure_default)
      end

      it 'sets the default success callback' do
        expect(layer.on_success).to eq(layer.on_success_default)
      end
    end

    context 'with a custom listener' do
      let(:custom_listener) { double('Listener') }
      let(:init_args) { { listener: custom_listener } }

      it 'sets the custom listener' do
        expect(layer.listener).to be(custom_listener)
      end
    end

    context 'with custom callbacks' do
      let(:init_args) do
        {
          on_failure: :custom_failure,
          on_success: :custom_success,
        }
      end

      it 'sets the custom failure callback' do
        expect(layer.on_failure).to eq(:custom_failure)
      end

      it 'sets the custom success callback' do
        expect(layer.on_success).to eq(:custom_success)
      end
    end
  end

  describe 'success/failure handling' do
    let(:listener) { spy('Listener') }
    let(:notifications) { [] }

    describe '#success' do
      subject(:layer) { success_class.new(listener: listener) }

      let(:success_class) do
        recorder = notifications
        Class.new(described_class) do
          observer -> { recorder << :success }, of_event: :success

          def call
            success(result: true)
          end
        end
      end

      execute do
        layer.call
      end

      it 'notifies success observers' do
        expect(notifications).to include(:success)
      end

      it 'calls the success callback on the listener' do
        expect(listener).to have_received(:on_success).with(result: true)
      end

      it 'exposes the payload as the result' do
        expect(layer.result).to eq(result: true)
      end
    end

    describe '#success with positional args' do
      subject(:layer) { success_class.new(listener: listener) }

      let(:success_class) do
        Class.new(described_class) do
          def call
            success('extra', result: true)
          end
        end
      end

      execute do
        layer.call
      end

      it 'passes the positional args to the listener' do
        expect(listener).to have_received(:on_success).with('extra', result: true)
      end

      it 'captures the positional args in the result' do
        expect(layer.result).to eq(result: true, success_args: ['extra'])
      end
    end

    describe '#failure' do
      subject(:layer) { failure_class.new(listener: listener) }

      let(:failure_class) do
        recorder = notifications
        Class.new(described_class) do
          observer -> { recorder << :failure }, of_event: :failure

          def call
            failure(error: 'test')
          end
        end
      end

      execute do
        layer.call
      end

      it 'notifies failure observers' do
        expect(notifications).to include(:failure)
      end

      it 'calls the failure callback on the listener' do
        expect(listener).to have_received(:on_failure).with(error: 'test')
      end

      it 'exposes the payload as the result' do
        expect(layer.result).to eq(error: 'test')
      end
    end

    describe '#failure with positional args' do
      subject(:layer) { failure_class.new(listener: listener) }

      let(:failure_class) do
        Class.new(described_class) do
          def call
            failure('extra', error: 'test')
          end
        end
      end

      execute do
        layer.call
      end

      it 'passes the positional args to the listener' do
        expect(listener).to have_received(:on_failure).with('extra', error: 'test')
      end

      it 'captures the positional args in the result' do
        expect(layer.result).to eq(error: 'test', failure_args: ['extra'])
      end
    end
  end

  describe 'instrumentation' do
    let(:listener) { spy('Listener') }
    let(:recordings) { [] }

    let(:first_instrumenter) do
      recorder = recordings
      Class.new(Layers::Instrumenter) do
        define_method(:instrument!) { |outcome| recorder << [:first, outcome] }
      end
    end

    let(:second_instrumenter) do
      recorder = recordings
      Class.new(Layers::Instrumenter) do
        define_method(:instrument!) { |outcome| recorder << [:second, outcome] }
      end
    end

    context 'with two instrumenters declared' do
      subject(:layer) { layer_class.new(listener: listener, on_success: :done) }

      let(:layer_class) do
        first = first_instrumenter
        second = second_instrumenter
        Class.new(described_class) do
          instrument first
          instrument second

          def call
            success(result: true)
          end
        end
      end

      execute do
        layer.call
      end

      it 'runs the instrumenters in declared order' do
        expect(recordings).to eq([[:first, :success], [:second, :success]])
      end

      it 'delivers the callback through the chain with the original name' do
        expect(listener).to have_received(:done).with(result: true)
      end
    end

    context 'with a subclass of an instrumented layer' do
      subject(:layer) { subclass.new(listener: listener) }

      let(:layer_class) do
        first = first_instrumenter
        Class.new(described_class) do
          instrument first

          def call
            success(result: true)
          end
        end
      end

      let(:subclass) { Class.new(layer_class) }

      execute do
        layer.call
      end

      it 'does not inherit the parent instrumenters' do
        expect(recordings).to be_empty
      end

      it 'still delivers the callback' do
        expect(listener).to have_received(:on_success).with(result: true)
      end
    end

    context 'with a duplicate declaration' do
      subject(:layer) { layer_class.new(listener: listener) }

      let(:layer_class) do
        first = first_instrumenter
        Class.new(described_class) do
          instrument first
          instrument first

          def call
            success(result: true)
          end
        end
      end

      execute do
        layer.call
      end

      it 'inserts the instrumenter once' do
        expect(recordings).to eq([[:first, :success]])
      end
    end

    context 'with a non-class argument' do
      it 'raises ArgumentError' do
        expect do
          Class.new(described_class) { instrument :timing }
        end.to raise_error(ArgumentError)
      end
    end
  end
end
