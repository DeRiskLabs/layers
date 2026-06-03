# frozen_string_literal: true

require 'layers_spec_helper'
require 'naught'

RSpec.describe Layers::DSL::NullListener do
  subject(:object_with_null_listener) do
    test_class.new
  end

  let(:test_class) do
    Class.new do
      include Layers::DSL::NullListener

      def call_null_listener
        null_listener
      end
    end
  end

  describe '#null_listener' do
    it 'returns a naught-generated null object' do
      expect(object_with_null_listener.call_null_listener).to be_a(Naught::BasicObject)
    end

    it 'returns the same null object on subsequent calls' do
      first_call = object_with_null_listener.call_null_listener
      second_call = object_with_null_listener.call_null_listener
      expect(first_call).to equal(second_call)
    end

    it 'responds to any method' do
      null_listener = object_with_null_listener.call_null_listener
      expect(null_listener.any_method).to be_nil
    end
  end
end
