# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::Observers do
  describe 'Class Methods' do
    subject(:test_class) { Class.new.include(described_class) }

    it { is_expected.to respond_to(:observer) }
    it { is_expected.to respond_to(:observers) }
    it { is_expected.to respond_to(:observer_exception_handler) }

    describe '.observer' do
      context 'when called with a method name' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Observers
            observer :foo
          end
        end

        it 'adds to success observers' do
          expect(test_class.observers[:success]).to include(:foo)
        end
      end

      context 'when called with multiple methods' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Observers
            observer :foo, :bar
          end
        end

        it 'adds all methods to success observers' do
          expect(test_class.observers[:success]).to include(:foo, :bar)
        end
      end

      context 'when called with specific event' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Observers
            observer :foo, of_event: :failure
          end
        end

        it 'adds method to specified event observers' do
          expect(test_class.observers[:failure]).to include(:foo)
        end

        it 'does not add to success observers' do
          expect(test_class.observers[:success]).to be_nil
        end
      end
    end

    describe '.observer_exception_handler' do
      subject(:test_class) do
        Class.new do
          include Layers::DSL::Observers
          observer_exception_handler :handle_error
        end
      end

      it 'sets the exception handler method' do
        expect(test_class.observer_exception_handler_method).to eq(:handle_error)
      end
    end
  end

  describe 'Instance Methods' do
    subject(:observer_object) { test_class.new }

    let(:test_class) do
      Class.new do
        include Layers::DSL::Observers

        observer :success_method
        observer :failure_method, of_event: :failure

        def success_method; end
        def failure_method; end
        def handle_error(error); end
      end
    end

    describe '#notify_observers' do
      before do
        allow(observer_object).to receive(:success_method)
        allow(observer_object).to receive(:failure_method)
        allow(observer_object).to receive(:handle_error)
      end

      context 'when called without event' do
        execute do
          observer_object.notify_observers
        end

        it 'calls success observers' do
          expect(observer_object).to have_received(:success_method)
        end

        it 'does not call failure observers' do
          expect(observer_object).not_to have_received(:failure_method)
        end
      end

      context 'when called with failure event' do
        execute do
          observer_object.notify_observers(of_event: :failure)
        end

        it 'calls failure observers' do
          expect(observer_object).to have_received(:failure_method)
        end

        it 'does not call success observers' do
          expect(observer_object).not_to have_received(:success_method)
        end
      end

      context 'when observer raises error' do
        let(:logger) { instance_double(Logger) }

        before do
          allow(observer_object).to receive(:success_method).and_raise(StandardError)
          allow(observer_object).to receive(:logger).and_return(logger)
          allow(logger).to receive(:warn)
          allow(logger).to receive(:debug)
        end

        it 'logs the error' do
          observer_object.notify_observers
          expect(logger).to have_received(:warn)
        end
      end
    end
  end
end
