# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::Emits do
  let(:layer_class) do
    Class.new(Layers::BaseLayer) do
      emits success: [:collaboration], failure: [:form]

      def call
        success(collaboration: :collaboration)
      end
    end
  end

  describe '.emits' do
    it 'declares the success keys as a set' do
      expect(layer_class.emitted_success_keys).to eq(Set.new([:collaboration]))
    end

    it 'declares the failure keys as a set' do
      expect(layer_class.emitted_failure_keys).to eq(Set.new([:form]))
    end

    it 'leaves undeclared outcomes nil' do
      undeclared = Class.new(Layers::BaseLayer) { emits success: [:collaboration] }
      expect(undeclared.emitted_failure_keys).to be_nil
    end

    it 'is per-class' do
      expect(Class.new(layer_class).emitted_success_keys).to be_nil
    end
  end

  describe 'emitter-side validation' do
    subject(:layer) { layer_class.new(listener: listener) }

    let(:listener) { spy('Listener') }

    context 'with the declared payload' do
      execute do
        layer.call
      end

      it 'delivers the callback' do
        expect(listener).to have_received(:on_success).with(collaboration: :collaboration)
      end
    end

    context 'with a declared key missing' do
      let(:layer_class) do
        Class.new(Layers::BaseLayer) do
          emits failure: [:form, :error]

          def call
            failure(form: :form)
          end
        end
      end

      it 'raises MissingDeclaredOutputs naming the keys' do
        expect do
          layer.call
        end.to raise_error(Layers::DSL::MissingDeclaredOutputs, /error/)
      end
    end

    context 'with an undeclared key emitted' do
      let(:layer_class) do
        Class.new(Layers::BaseLayer) do
          emits success: [:collaboration]

          def call
            success(collaboration: :collaboration, extra: :extra)
          end
        end
      end

      it 'raises UndeclaredOutputs naming the keys' do
        expect do
          layer.call
        end.to raise_error(Layers::DSL::UndeclaredOutputs, /extra/)
      end
    end

    context 'with an undeclared outcome' do
      let(:layer_class) do
        Class.new(Layers::BaseLayer) do
          emits success: [:collaboration]

          def call
            failure(anything: :goes)
          end
        end
      end

      execute do
        layer.call
      end

      it 'does not validate that outcome' do
        expect(listener).to have_received(:on_failure).with(anything: :goes)
      end
    end
  end

  describe 'listener contract verification' do
    context 'with a callback matching the declared keys' do
      let(:listener_class) do
        Class.new do
          def on_success(collaboration:); end
          def on_failure(form:); end
        end
      end

      it 'constructs' do
        expect(layer_class.new(listener: listener_class.new)).to be_a(Layers::BaseLayer)
      end
    end

    context 'with a callback requiring a keyword never emitted' do
      let(:listener_class) do
        Class.new do
          def on_success(collaboration:, audit_trail:); end
          def on_failure(form:); end
        end
      end

      it 'raises ContractViolation at construction' do
        expect do
          layer_class.new(listener: listener_class.new)
        end.to raise_error(Layers::ContractViolation, /audit_trail/)
      end
    end

    context 'with a callback unable to receive a declared key' do
      let(:listener_class) do
        Class.new do
          def on_success(collaboration:); end
          def on_failure(message: nil); end
        end
      end

      it 'raises ContractViolation at construction' do
        expect do
          layer_class.new(listener: listener_class.new)
        end.to raise_error(Layers::ContractViolation, /cannot receive failure keys/)
      end
    end

    context 'with a keyrest callback' do
      let(:listener_class) do
        Class.new do
          def on_success(**args); end
          def on_failure(**args); end
        end
      end

      it 'constructs' do
        expect(layer_class.new(listener: listener_class.new)).to be_a(Layers::BaseLayer)
      end
    end

    context 'with optional keywords covering the declared keys' do
      let(:listener_class) do
        Class.new do
          def on_success(collaboration: nil); end
          def on_failure(form: nil); end
        end
      end

      it 'constructs' do
        expect(layer_class.new(listener: listener_class.new)).to be_a(Layers::BaseLayer)
      end
    end

    context 'with custom callback names' do
      let(:listener_class) do
        Class.new do
          def created(collaboration:); end
          def failed(message:); end
        end
      end

      it 'verifies the named callbacks' do
        expect do
          layer_class.new(listener: listener_class.new, on_success: :created, on_failure: :failed)
        end.to raise_error(Layers::ContractViolation, /failed/)
      end
    end

    context 'with no listener' do
      it 'constructs fire-and-forget' do
        expect(layer_class.new).to be_a(Layers::BaseLayer)
      end
    end

    context 'with a method_missing listener' do
      let(:listener_class) do
        Class.new do
          def method_missing(*_args, **_opts)
            self
          end

          def respond_to_missing?(*)
            true
          end
        end
      end

      it 'skips verification' do
        expect(layer_class.new(listener: listener_class.new)).to be_a(Layers::BaseLayer)
      end
    end

    context 'with a positional-only callback' do
      let(:listener_class) do
        Class.new do
          def on_success(payload); end
          def on_failure(payload); end
        end
      end

      it 'skips verification' do
        expect(layer_class.new(listener: listener_class.new)).to be_a(Layers::BaseLayer)
      end
    end

    context 'with an instrumented layer' do
      let(:layer_class) do
        Class.new(Layers::BaseLayer) do
          emits success: [:collaboration]
          instrument Layers::Instrumenter

          def call
            success(collaboration: :collaboration)
          end
        end
      end

      let(:listener_class) do
        Class.new do
          def on_success(wrong_key:); end
        end
      end

      it 'verifies the original listener behind the chain' do
        expect do
          layer_class.new(listener: listener_class.new)
        end.to raise_error(Layers::ContractViolation, /wrong_key/)
      end
    end
  end
end
