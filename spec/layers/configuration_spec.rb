# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Configuration do
  subject(:configuration) { described_class.new }

  it { is_expected.to respond_to(:logger) }
  it { is_expected.to respond_to(:logger=) }

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
