# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UseCases::Widgets::Create do
  subject(:use_case) { described_class.new(**params) }

  let(:listener) { spy('Listener') }
  let(:on_success_callback) { :on_success }
  let(:on_failure_callback) { :on_failure }

  let(:valid_listener_args) do
    {
      listener: listener,
      on_success: on_success_callback,
      on_failure: on_failure_callback,
    }
  end

  let(:name) { 'sprocket' }
  let(:valid_use_case_args) { { name: name } }
  let(:valid_params) { valid_listener_args.merge(valid_use_case_args) }
  let(:params) { valid_params }

  describe '.call' do
    context 'with a valid name' do
      it 'persists the widget' do
        expect { use_case.call }.to change(Widget, :count).by(1)
      end

      context 'after running' do
        execute { use_case.call }

        it 'notifies the listener of success' do
          expect(listener).to have_received(on_success_callback)
        end
      end
    end

    context 'with a blank name' do
      let(:name) { '' }

      it 'does not persist a widget' do
        expect { use_case.call }.not_to change(Widget, :count)
      end

      context 'after running' do
        execute { use_case.call }

        it 'notifies the listener of failure' do
          expect(listener).to have_received(on_failure_callback)
        end
      end
    end

    context 'with a missing required input' do
      let(:valid_use_case_args) { {} }

      it 'raises MissingRequiredInputs' do
        expect { use_case.call }.to raise_error(Layers::DSL::MissingRequiredInputs)
      end
    end

    context 'with a mis-wired listener' do
      let(:listener) do
        Class.new do
          def on_success(gadget:); end

          def on_failure(**); end
        end.new
      end

      it 'fails at construction' do
        expect { use_case }.to raise_error(Layers::ContractViolation)
      end
    end
  end
end
