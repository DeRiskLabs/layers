# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Adapters::Relation::DuckType do
  describe '.relation?' do
    context 'with an object answering the relation protocol' do
      let(:relation) { double('Relation', where: nil) }

      it 'accepts the object' do
        expect(described_class.relation?(relation)).to be(true)
      end
    end

    context 'with an object that does not answer the relation protocol' do
      it 'rejects the object' do
        expect(described_class.relation?('not a relation')).to be(false)
      end
    end
  end
end
