# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::ClassCallable do
  describe 'Class Methods' do
    describe '.call' do
      let(:test_class) do
        Class.new do
          include Layers::DSL::ClassCallable

          attr_reader :args, :opts

          def initialize(*args, **opts)
            @args = args
            @opts = opts
          end

          def call
            { args: args, opts: opts }
          end
        end
      end

      execute do
        test_class.call('arg1', test: true)
      end

      it 'instantiates and calls the class' do
        expect(execute_result).to eq({ args: ['arg1'], opts: { test: true } })
      end
    end
  end

  describe 'Instance Methods' do
    describe '#call' do
      subject(:callable_object) { test_class.new }

      let(:test_class) do
        Class.new do
          include Layers::DSL::ClassCallable
        end
      end

      it 'requires implementation of #call' do
        expect { callable_object.call }.to raise_error(NotImplementedError)
      end
    end
  end
end
