# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Adapters::Pagination::WillPaginate do
  let(:relation) { spy('relation') }
  let(:refined_relation) { double('RefinedRelation') }

  describe '.page' do
    before do
      allow(relation).to receive(:page).and_return(refined_relation)
    end

    execute(:paged) do
      described_class.page(relation, 2)
    end

    it 'pages the relation' do
      expect(relation).to have_received(:page).with(2)
    end

    it 'returns the paged relation' do
      expect(paged).to be(refined_relation)
    end
  end

  describe '.per' do
    before do
      allow(relation).to receive(:per_page).and_return(refined_relation)
    end

    execute(:sized) do
      described_class.per(relation, 25)
    end

    it 'sets the page size on the relation' do
      expect(relation).to have_received(:per_page).with(25)
    end

    it 'returns the sized relation' do
      expect(sized).to be(refined_relation)
    end
  end
end
