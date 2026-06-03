# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Configuration do
  subject(:configuration) { described_class.new }

  it { is_expected.to respond_to(:logger) }
  it { is_expected.to respond_to(:logger=) }
end

RSpec.describe Layers do
  after do
    described_class.instance_variable_set(:@configuration, nil)
  end

  describe '.configuration' do
    it 'returns a configuration' do
      expect(described_class.configuration).to be_a(Layers::Configuration)
    end

    it 'memoizes the configuration' do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe '.configure' do
    let(:logger) { instance_double(Logger) }

    execute do
      described_class.configure { |config| config.logger = logger }
    end

    it 'yields the configuration for assignment' do
      expect(described_class.configuration.logger).to be(logger)
    end
  end
end
