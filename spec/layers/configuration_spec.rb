# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Configuration do
  subject(:configuration) { described_class.new }

  it { is_expected.to respond_to(:logger) }
  it { is_expected.to respond_to(:logger=) }

  describe '#relation_adapter' do
    it 'defaults to the ActiveRecord adapter' do
      expect(configuration.relation_adapter).to be(Layers::Adapters::Relation::ActiveRecord)
    end

    context 'when an adapter is assigned' do
      let(:custom_adapter) { double('RelationAdapter') }

      before do
        configuration.relation_adapter = custom_adapter
      end

      it 'returns the assigned adapter' do
        expect(configuration.relation_adapter).to be(custom_adapter)
      end
    end
  end

  describe '#pagination_adapter' do
    context 'when Kaminari is present' do
      before do
        stub_const('Kaminari', Module.new)
      end

      it 'detects the Kaminari adapter' do
        expect(configuration.pagination_adapter).to be(Layers::Adapters::Pagination::Kaminari)
      end
    end

    context 'when no pagination gem is present' do
      it 'falls back to the WillPaginate adapter' do
        expect(configuration.pagination_adapter).to be(Layers::Adapters::Pagination::WillPaginate)
      end
    end

    context 'when an adapter is assigned' do
      let(:custom_adapter) { double('PaginationAdapter') }

      before do
        configuration.pagination_adapter = custom_adapter
      end

      it 'returns the assigned adapter' do
        expect(configuration.pagination_adapter).to be(custom_adapter)
      end
    end
  end

  describe '#graphql_execution_error' do
    context 'when GraphQL is present' do
      let(:execution_error) { Class.new(StandardError) }

      before do
        stub_const('GraphQL::ExecutionError', execution_error)
      end

      it 'detects the GraphQL execution error' do
        expect(configuration.graphql_execution_error).to be(execution_error)
      end
    end

    context 'when GraphQL is absent' do
      it 'is nil' do
        expect(configuration.graphql_execution_error).to be_nil
      end
    end

    context 'when an error class is assigned' do
      let(:custom_error) { Class.new(StandardError) }

      before do
        configuration.graphql_execution_error = custom_error
      end

      it 'returns the assigned error class' do
        expect(configuration.graphql_execution_error).to be(custom_error)
      end
    end
  end

  describe 'Layers.configuration' do
    after do
      Layers.instance_variable_set(:@configuration, nil)
    end

    let(:first_access) { Layers.configuration }

    it 'returns a configuration' do
      expect(Layers.configuration).to be_a(described_class)
    end

    it 'memoizes the configuration' do
      expect(Layers.configuration).to be(first_access)
    end
  end

  describe 'Layers.configure' do
    after do
      Layers.instance_variable_set(:@configuration, nil)
    end

    let(:logger) { instance_double(Logger) }

    execute do
      Layers.configure { |config| config.logger = logger }
    end

    it 'yields the configuration for assignment' do
      expect(Layers.configuration.logger).to be(logger)
    end
  end
end
