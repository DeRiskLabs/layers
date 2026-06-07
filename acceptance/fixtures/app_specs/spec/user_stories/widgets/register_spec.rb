# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserStories::Widgets::Register do
  let(:listener) { spy('Listener') }

  before do
    $acceptance_events = []
    described_class.call(name: 'gadget', listener: listener)
  end

  it 'notifies success through the daisy chain' do
    expect(listener).to have_received(:on_success) do |payload|
      expect(payload.fetch(:widget).name).to eq('gadget')
    end
  end

  it 'fires the success observer' do
    expect($acceptance_events).to include(:announced)
  end

  it 'routes the outcome through the instrumenter' do
    expect($acceptance_events).to include([:instrumented, :success])
  end
end
