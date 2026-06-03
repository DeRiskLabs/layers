# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Adapters::Relation::ActiveRecord do
  describe '.relation?' do
    context 'with a class' do
      it 'accepts the class' do
        expect(described_class.relation?(Class.new)).to be(true)
      end
    end

    context 'when ActiveRecord is present' do
      let(:relation_class) { Class.new }

      before do
        stub_const('ActiveRecord::Relation', relation_class)
      end

      it 'accepts a relation instance' do
        expect(described_class.relation?(relation_class.new)).to be(true)
      end

      it 'rejects other objects' do
        expect(described_class.relation?('not a relation')).to be(false)
      end
    end

    context 'when ActiveRecord is absent' do
      it 'rejects non-class objects' do
        expect(described_class.relation?('not a relation')).to be(false)
      end
    end
  end
end
