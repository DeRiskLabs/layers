# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::QueryBuilder::Sort do
  subject(:query) { test_class.new(relation) }

  let(:test_class) do
    Class.new do
      include Layers::QueryBuilder::Sort

      attr_reader :relation

      def initialize(relation)
        @relation = relation
      end
    end
  end

  let(:relation) { spy('relation') }

  describe '#order' do
    context 'with default arguments' do
      execute(:chained) do
        query.order
      end

      it 'returns the query for further chaining' do
        expect(chained).to be(query)
      end

      it 'orders by created_at descending' do
        expect(relation).to have_received(:order).with(created_at: :desc)
      end
    end

    context 'with a custom field and direction' do
      execute(:chained) do
        query.order(sort_field: :name, sort_direction: :asc)
      end

      it 'orders by the given field and direction' do
        expect(relation).to have_received(:order).with(name: :asc)
      end
    end
  end
end
