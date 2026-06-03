# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::CallbackDefaults do
  describe 'Class Methods' do
    subject(:test_class) { Class.new.include(described_class) }

    it { is_expected.to respond_to(:default_callbacks) }
    it { is_expected.to respond_to(:on_failure_default) }
    it { is_expected.to respond_to(:on_success_default) }

    describe '.default_callbacks' do
      subject(:test_class) do
        Class.new do
          include Layers::DSL::CallbackDefaults
          default_callbacks on_failure: :custom_failure,
                            on_success: :custom_success
        end
      end

      it 'sets custom failure callback' do
        expect(test_class.on_failure_default).to eq(:custom_failure)
      end

      it 'sets custom success callback' do
        expect(test_class.on_success_default).to eq(:custom_success)
      end
    end

    context 'when no defaults are set' do
      subject(:test_class) do
        Class.new do
          include Layers::DSL::CallbackDefaults
        end
      end

      it 'uses default failure callback' do
        expect(test_class.on_failure_default).to eq(described_class::ON_FAILURE_DEFAULT_CALLBACK)
      end

      it 'uses default success callback' do
        expect(test_class.on_success_default).to eq(described_class::ON_SUCCESS_DEFAULT_CALLBACK)
      end
    end
  end

  describe 'Instance Methods' do
    describe '#initialize' do
      subject(:callback_object) { test_class.allocate }

      let(:test_class) do
        Class.new do
          include Layers::DSL::CallbackDefaults
          default_callbacks on_failure: :custom_failure,
                            on_success: :custom_success
        end
      end

      execute do
        callback_object.send(:initialize)
      end

      it 'sets the failure default from the class' do
        expect(callback_object.on_failure_default).to eq(:custom_failure)
      end

      it 'sets the success default from the class' do
        expect(callback_object.on_success_default).to eq(:custom_success)
      end
    end
  end
end
