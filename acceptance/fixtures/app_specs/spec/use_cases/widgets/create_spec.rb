# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UseCases::Widgets::Create do
  let(:listener) { spy('Listener') }

  context 'with a valid name' do
    before { described_class.call(name: 'sprocket', listener: listener) }

    it 'notifies success with the persisted widget' do
      expect(listener).to have_received(:on_success) do |payload|
        expect(payload.fetch(:widget)).to be_persisted
      end
    end
  end

  context 'with a blank name' do
    before { described_class.call(name: '', listener: listener) }

    it 'notifies failure with errors' do
      expect(listener).to have_received(:on_failure) do |payload|
        expect(payload.fetch(:errors)).to be_any
      end
    end
  end

  context 'with a missing required input' do
    it 'raises MissingRequiredInputs' do
      expect { described_class.call(listener: listener) }
        .to raise_error(Layers::DSL::MissingRequiredInputs)
    end
  end

  context 'with a mis-wired listener' do
    let(:mis_wired_listener) do
      Class.new do
        def on_success(gadget:); end

        def on_failure(**); end
      end.new
    end

    it 'fails at construction' do
      expect { described_class.new(name: 'sprocket', listener: mis_wired_listener) }
        .to raise_error(Layers::ContractViolation)
    end
  end
end
