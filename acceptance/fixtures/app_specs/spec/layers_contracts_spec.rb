# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'output contracts' do
  let(:listener) { spy('Listener') }

  let(:over_emitter) do
    Class.new(Layers::BaseLayer) do
      emits success: [:widget]

      def call
        success(widget: :widget, extra: :extra)
      end
    end
  end

  let(:under_emitter) do
    Class.new(Layers::BaseLayer) do
      emits success: [:widget]

      def call
        success
      end
    end
  end

  it 'raises on undeclared output keys' do
    expect { over_emitter.call(listener: listener) }
      .to raise_error(Layers::DSL::UndeclaredOutputs)
  end

  it 'raises on missing declared output keys' do
    expect { under_emitter.call(listener: listener) }
      .to raise_error(Layers::DSL::MissingDeclaredOutputs)
  end
end
