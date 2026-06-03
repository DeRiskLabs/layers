# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::ClassCallable do
  describe 'Class Methods' do
    describe '.call' do
      context 'when the class implements #call' do
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

      context 'when a TypeError is caused by a missing method' do
        let(:test_class) do
          Class.new do
            include Layers::DSL::ClassCallable

            def call
              missing_delegation
            rescue NameError
              raise TypeError, 'no implicit conversion'
            end
          end
        end

        it 'wraps the error in MissingMethodError' do
          expect do
            test_class.call
          end.to raise_error(Layers::DSL::ClassCallable::MissingMethodError, /missing_delegation/)
        end
      end

      context 'when a TypeError has no missing method cause' do
        let(:test_class) do
          Class.new do
            include Layers::DSL::ClassCallable

            def call
              raise TypeError, 'no implicit conversion'
            end
          end
        end

        it 're-raises the TypeError' do
          expect do
            test_class.call
          end.to raise_error(TypeError, 'no implicit conversion')
        end
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
