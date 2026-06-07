# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::WidgetsQuery do
  subject(:query) { described_class.new }

  before do
    ['beta', 'alpha', 'gamma'].each { |name| Widget.create!(name: name) }
  end

  it 'counts through the relation' do
    expect(query.count).to eq(3)
  end

  it 'returns itself from refiners' do
    expect(query.order(sort_field: :name, sort_direction: :asc)).to be(query)
  end

  it 'orders and paginates through kaminari' do
    names = described_class.new
                           .order(sort_field: :name, sort_direction: :asc)
                           .page(1)
                           .per(2)
                           .all
                           .map(&:name)
    expect(names).to eq(['alpha', 'beta'])
  end

  it 'raises when per is called before page' do
    expect { described_class.new.per(2) }
      .to raise_error(Layers::QueryBuilder::PaginationError)
  end
end
