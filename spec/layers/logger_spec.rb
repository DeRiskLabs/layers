# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Logger do
  after do
    described_class.instance_variable_set(:@logger, nil)
    Layers.instance_variable_set(:@configuration, nil)
  end

  describe '.logger' do
    context 'when a logger is configured' do
      let(:configured_logger) { instance_double(::Logger) }

      before do
        Layers.configure { |config| config.logger = configured_logger }
      end

      execute(:logger) do
        described_class.logger
      end

      it 'returns the configured logger' do
        expect(logger).to be(configured_logger)
      end
    end

    context 'when a logger is configured and Rails is present' do
      let(:configured_logger) { instance_double(::Logger) }
      let(:rails_logger) { instance_double(::Logger) }
      let(:rails_env) { double('Env', production?: false) }
      let(:rails) { double('Rails', env: rails_env, logger: rails_logger) }

      before do
        stub_const('Rails', rails)
        Layers.configure { |config| config.logger = configured_logger }
      end

      execute(:logger) do
        described_class.logger
      end

      it 'prefers the configured logger' do
        expect(logger).to be(configured_logger)
      end
    end

    context 'when Rails provides a logger outside production' do
      let(:rails_logger) { instance_double(::Logger) }
      let(:rails_env) { double('Env', production?: false) }
      let(:rails) { double('Rails', env: rails_env, logger: rails_logger) }

      before do
        stub_const('Rails', rails)
      end

      execute(:logger) do
        described_class.logger
      end

      it 'returns the Rails logger' do
        expect(logger).to be(rails_logger)
      end
    end

    context 'when Rails is in production' do
      let(:rails_logger) { instance_double(::Logger) }
      let(:rails_env) { double('Env', production?: true) }
      let(:rails_root) { double('Root', join: StringIO.new) }
      let(:rails) { double('Rails', env: rails_env, logger: rails_logger, root: rails_root) }

      before do
        Singleton.__init__(described_class)
        stub_const('Rails', rails)
      end

      execute(:logger) do
        described_class.logger
      end

      it 'falls back to the singleton instance' do
        expect(logger).to be(described_class.instance)
      end
    end

    context 'when Rails has no logger' do
      let(:rails_env) { double('Env', production?: false) }
      let(:rails_root) { double('Root', join: StringIO.new) }
      let(:rails) { double('Rails', env: rails_env, logger: nil, root: rails_root) }

      before do
        Singleton.__init__(described_class)
        stub_const('Rails', rails)
      end

      execute(:logger) do
        described_class.logger
      end

      it 'falls back to the singleton instance' do
        expect(logger).to be(described_class.instance)
      end
    end

    context 'when nothing is configured' do
      before do
        Singleton.__init__(described_class)
        allow(File).to receive(:open).with('log/layers.log', 'a').and_return(StringIO.new)
      end

      execute(:logger) do
        described_class.logger
      end

      it 'falls back to the singleton instance' do
        expect(logger).to be(described_class.instance)
      end
    end
  end
end
