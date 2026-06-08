# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserStories::Widgets::Register do
  subject(:user_story) { described_class.new(**params) }

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

  let(:valid_use_case_args) { { name: 'gadget' } }
  let(:valid_params) { valid_listener_args.merge(valid_use_case_args) }
  let(:params) { valid_params }

  describe '.call' do
    before { $acceptance_events = [] }

    execute do
      user_story.call
    end

    it 'notifies the listener of success' do
      expect(listener).to have_received(on_success_callback)
    end

    it 'fires the success observer' do
      expect($acceptance_events).to include(:announced)
    end

    it 'routes the outcome through the instrumenter' do
      expect($acceptance_events).to include([:instrumented, :success])
    end
  end
end
