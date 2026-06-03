# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::QueryBuilder::Paginate do
  subject(:query) { test_class.new(relation) }

  let(:test_class) do
    Class.new do
      include Layers::QueryBuilder::Paginate

      attr_reader :relation

      def initialize(relation)
        @relation = relation
      end
    end
  end

  let(:relation) { spy('relation') }

  describe '#page' do
    execute(:chained) do
      query.page(2)
    end

    it 'returns the query for further chaining' do
      expect(chained).to be(query)
    end

    it 'pages the relation' do
      expect(relation).to have_received(:page).with(2)
    end

    it 'marks the query paginated' do
      expect(query.paginated).to be(true)
    end
  end

  describe '#per' do
    context 'when the query is paginated' do
      execute(:chained) do
        query.page(2).per(25)
      end

      it 'returns the query for further chaining' do
        expect(chained).to be(query)
      end

      it 'sets the page size on the relation' do
        expect(relation).to have_received(:per_page).with(25)
      end
    end

    context 'when the query is not paginated' do
      it 'raises PaginationError' do
        expect do
          query.per(25)
        end.to raise_error(Layers::QueryBuilder::PaginationError)
      end
    end
  end

  describe '#paginated' do
    it 'is nil before pagination' do
      expect(query.paginated).to be_nil
    end
  end

  context 'with a configured pagination adapter' do
    let(:adapter) { spy('PaginationAdapter') }

    before do
      Layers.configure { |config| config.pagination_adapter = adapter }
    end

    execute do
      query.page(2)
    end

    it 'delegates paging to the adapter' do
      expect(adapter).to have_received(:page).with(relation, 2)
    end
  end
end
