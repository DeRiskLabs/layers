# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::QueryBuilder::RelationDefaults do
  describe 'Class Methods' do
    subject(:test_class) { Class.new.include(described_class) }

    it { is_expected.to respond_to(:relation_class) }
    it { is_expected.to respond_to(:default_relation_class) }
    it { is_expected.to respond_to(:default_relation_class_name) }

    describe '.relation_class' do
      context 'when called with a name' do
        subject(:test_class) do
          Class.new do
            include Layers::QueryBuilder::RelationDefaults
            relation_class :my_model
          end
        end

        it 'camelizes the relation class name' do
          expect(test_class.default_relation_class_name).to eq('MyModel')
        end
      end

      context 'when called with a callable' do
        subject(:test_class) do
          Class.new do
            include Layers::QueryBuilder::RelationDefaults
            relation_class -> { 'MyModel' }
          end
        end

        it 'uses the callable result as the name' do
          expect(test_class.default_relation_class_name).to eq('MyModel')
        end
      end
    end

    describe '.default_relation_class' do
      context 'when the name constantizes' do
        subject(:test_class) do
          Class.new do
            include Layers::QueryBuilder::RelationDefaults
            relation_class :my_model
          end
        end

        let(:my_model) { Class.new }

        before do
          stub_const('MyModel', my_model)
        end

        it 'returns the model class' do
          expect(test_class.default_relation_class).to be(my_model)
        end
      end

      context 'when no relation class is declared' do
        it 'returns nil' do
          expect(test_class.default_relation_class).to be_nil
        end
      end

      context 'when the name does not constantize' do
        subject(:test_class) do
          Class.new do
            include Layers::QueryBuilder::RelationDefaults
            relation_class :missing_model
          end
        end

        it 'raises ConfigurationError' do
          expect do
            test_class.default_relation_class
          end.to raise_error(Layers::QueryBuilder::ConfigurationError)
        end
      end
    end
  end

  describe 'Instance Methods' do
    describe '#default_initial_relation' do
      subject(:instance) { test_class.new }

      let(:test_class) do
        Class.new do
          include Layers::QueryBuilder::RelationDefaults
          relation_class :my_model
        end
      end

      let(:my_model) { Class.new }

      before do
        stub_const('MyModel', my_model)
      end

      it 'returns the class default relation class' do
        expect(instance.default_initial_relation).to be(my_model)
      end
    end
  end
end
