# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::DSL::Inputs do
  describe 'Class Methods' do
    subject(:test_class) { Class.new.include(described_class) }

    it { is_expected.to respond_to(:all_inputs) }
    it { is_expected.to respond_to(:optional) }
    it { is_expected.to respond_to(:optional_inputs) }
    it { is_expected.to respond_to(:required) }
    it { is_expected.to respond_to(:required_inputs) }
    it { is_expected.to respond_to(:optional_with_default) }
    it { is_expected.to respond_to(:default_inputs) }

    describe '.optional' do
      context 'when called with a symbol for an input name' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            optional :foo
          end
        end

        it 'adds the input name to the list of optional_inputs' do
          expect(test_class.optional_inputs).to include(:foo)
        end

        it 'endows instances with a reader method' do
          expect(test_class.new).to respond_to(:foo)
        end

        it 'endows instances with a writer method' do
          expect(test_class.new).to respond_to(:foo=)
        end
      end

      context 'when called with multiple symbols' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            optional :foo, :bar
          end
        end

        it 'adds inputs for each symbol' do
          expect(test_class.optional_inputs).to include(:foo, :bar)
        end
      end
    end

    describe '.required' do
      context 'when called with a symbol for an input name' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            required :foo
          end
        end

        it 'adds the input name to the list of required_inputs' do
          expect(test_class.required_inputs).to include(:foo)
        end

        it 'endows instances with a reader method' do
          expect(test_class.allocate).to respond_to(:foo)
        end

        it 'endows instances with a writer method' do
          expect(test_class.allocate).to respond_to(:foo=)
        end
      end

      context 'when called with multiple symbols' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            required :foo, :bar
          end
        end

        it 'adds inputs for each symbol' do
          expect(test_class.required_inputs).to include(:foo, :bar)
        end
      end
    end

    describe '.optional_with_default' do
      context 'when called with a hash' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            optional_with_default foo: []
          end
        end

        it 'adds to optional_inputs' do
          expect(test_class.optional_inputs).to include(:foo)
        end

        it 'adds to default_inputs' do
          expect(test_class.default_inputs).to include(:foo)
        end

        it 'sets the default value' do
          expect(test_class.default_inputs[:foo]).to eq([])
        end
      end

      context 'when called with multiple defaults' do
        subject(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            optional_with_default foo: [], bar: {}
          end
        end

        it 'adds all optional inputs' do
          expect(test_class.optional_inputs).to include(:foo, :bar)
        end

        it 'sets all defaults' do
          expect(test_class.default_inputs).to eq({ foo: [], bar: {} })
        end
      end
    end
  end

  describe 'Instance Methods' do
    subject(:input_object) { test_class.allocate }

    let(:test_class) do
      Class.new do
        include Layers::DSL::Inputs
        required :foo, :bar
        optional :baz, :qux
      end
    end

    it { is_expected.to respond_to(:inputs) }

    describe '#initialize' do
      let(:required_inputs) { { foo: true, bar: false } }
      let(:optional_inputs) { { baz: :awesome } }
      let(:test_args) { required_inputs.merge(optional_inputs) }

      context 'with valid inputs' do
        execute do
          input_object.send(:initialize, **test_args)
        end

        it 'sets the inputs hash' do
          expect(input_object.inputs).to eq(test_args)
        end

        it 'sets attributes for all inputs' do
          test_args.each do |input_name, input_value|
            expect(input_object.send(input_name)).to eq(input_value)
          end
        end
      end

      context 'with missing required inputs' do
        let(:required_inputs) { {} }

        it 'raises MissingRequiredInputs' do
          expect do
            input_object.send(:initialize, **test_args)
          end.to raise_error(Layers::DSL::MissingRequiredInputs)
        end
      end

      context 'with undeclared inputs' do
        let(:optional_inputs) { { baz: true, qux: false, extra: :bad } }

        it 'raises UnexpectedInputs' do
          expect do
            input_object.send(:initialize, **test_args)
          end.to raise_error(Layers::DSL::UnexpectedInputs)
        end
      end

      context 'with default values' do
        let(:test_class) do
          Class.new do
            include Layers::DSL::Inputs
            required :foo, :bar
            optional :baz, :qux
            optional_with_default qux: :default_value
          end
        end

        execute do
          input_object.send(:initialize, **test_args)
        end

        it 'includes defaults in inputs hash' do
          expect(input_object.inputs).to eq(test_args.merge(qux: :default_value))
        end
      end
    end

    context 'when initialized with valid inputs' do
      let(:required_inputs) { { foo: true, bar: false } }
      let(:optional_inputs) { { baz: :awesome } }
      let(:test_args) { required_inputs.merge(optional_inputs) }

      before do
        input_object.send(:initialize, **test_args)
      end

      describe '#optional_attributes' do
        it 'returns optional inputs with values' do
          expect(input_object.optional_attributes).to eq({
                                                           baz: :awesome,
                                                           qux: nil,
                                                         })
        end
      end

      describe '#required_attributes' do
        it 'returns required inputs with values' do
          expect(input_object.required_attributes).to eq({
                                                           foo: true,
                                                           bar: false,
                                                         })
        end
      end

      describe '#attributes' do
        it 'returns all inputs with values' do
          expect(input_object.attributes).to eq({
                                                  foo: true,
                                                  bar: false,
                                                  baz: :awesome,
                                                  qux: nil,
                                                })
        end
      end
    end
  end
end
