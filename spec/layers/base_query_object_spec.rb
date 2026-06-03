# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::BaseQueryObject do
  before do
    stub_const('ActiveRecord::Relation', relation_interface)
  end

  it { expect(described_class.included_modules).to include(Layers::QueryBuilder::RelationDefaults) }
  it { expect(described_class.included_modules).to include(Layers::QueryBuilder::Paginate) }
  it { expect(described_class.included_modules).to include(Layers::QueryBuilder::Sort) }

  let(:test_class) do
    Class.new(described_class) do
      def build_relation_defaults!; end
    end
  end

  let(:relation_interface) do
    Class.new do
      def where(*); end
    end
  end


  describe '#initialize' do
    subject(:query) { test_class.allocate }

    let(:relation) { relation_interface.new }
    let(:init_args) { [relation] }
    let(:init_opts) { {} }

    execute do
      query.send(:initialize, *init_args, **init_opts)
    end

    context 'with a relation argument' do
      it 'sets the relation' do
        expect(query.relation).to be(relation)
      end

      it 'sets the unscoped relation' do
        expect(query.unscoped_relation).to be(relation)
      end

      it 'has empty options' do
        expect(query.options).to eq({})
      end
    end

    context 'with a model class as the relation' do
      let(:relation) { Class.new }

      it 'accepts the class as the relation' do
        expect(query.relation).to be(relation)
      end
    end

    context 'with a relation option' do
      let(:option_relation) { relation_interface.new }
      let(:init_opts) { { relation: option_relation } }

      it 'prefers the option over the argument' do
        expect(query.relation).to be(option_relation)
      end

      it 'keeps the option in the options hash' do
        expect(query.options).to eq({ relation: option_relation })
      end
    end

    context 'with no relation' do
      let(:test_class) do
        Class.new(described_class) do
          relation_class :my_model

          def build_relation_defaults!; end
        end
      end

      let(:my_model) { Class.new }
      let(:init_args) { [] }

      before do
        stub_const('MyModel', my_model)
      end

      it 'falls back to the default initial relation' do
        expect(query.relation).to be(my_model)
      end
    end
  end

  describe 'relation validation' do
    context 'with an invalid relation' do
      it 'raises RelationError' do
        expect do
          test_class.new('not a relation')
        end.to raise_error(Layers::BaseQueryObject::RelationError)
      end
    end
  end

  describe 'subclass contract' do
    it 'requires subclasses to implement #build_relation_defaults!' do
      expect do
        Class.new(described_class).new(relation_interface.new)
      end.to raise_error(NotImplementedError)
    end
  end

  describe 'delegation' do
    subject(:query) { test_class.new(relation) }

    let(:relation) { relation_interface.new }

    it { is_expected.to respond_to(:all) }
    it { is_expected.to respond_to(:count) }
    it { is_expected.to respond_to(:find) }
    it { is_expected.to respond_to(:find_by) }
    it { is_expected.to respond_to(:find_by!) }
    it { is_expected.to respond_to(:first) }
    it { is_expected.to respond_to(:includes) }
    it { is_expected.to respond_to(:joins) }
    it { is_expected.to respond_to(:last) }
    it { is_expected.to respond_to(:left_joins) }
    it { is_expected.to respond_to(:limit) }
    it { is_expected.to respond_to(:none) }
    it { is_expected.to respond_to(:offset) }
    it { is_expected.to respond_to(:pluck) }
    it { is_expected.to respond_to(:select) }
    it { is_expected.to respond_to(:where) }

    describe 'forwarding' do
      before do
        allow(relation).to receive(:where)
      end

      execute do
        query.where(id: 1)
      end

      it 'forwards the message to the relation' do
        expect(relation).to have_received(:where).with(id: 1)
      end
    end
  end
end
