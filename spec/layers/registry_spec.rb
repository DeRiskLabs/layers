# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Registry do
  subject(:registry) { described_class.new(entries) }

  let(:entries) { { identity_repository: 'Identity' } }

  describe '#[]' do
    context 'with a string entry' do
      let(:identity_class) { Class.new }

      before do
        stub_const('Identity', identity_class)
      end

      it 'constantizes the entry' do
        expect(registry[:identity_repository]).to be(identity_class)
      end
    end

    context 'with an entry registered after the constant would have loaded' do
      it 'resolves lazily at access time' do
        late_registry = described_class.new(late_repository: 'LateArrival')
        stub_const('LateArrival', Class.new)
        expect(late_registry[:late_repository]).to be(LateArrival)
      end
    end

    context 'with a non-string entry' do
      let(:fake_repository) { double('FakeRepository') }
      let(:entries) { { identity_repository: fake_repository } }

      it 'passes the entry through untouched' do
        expect(registry[:identity_repository]).to be(fake_repository)
      end
    end

    context 'with a string-keyed registration' do
      let(:entries) { { 'identity_repository' => 'Identity' } }

      before do
        stub_const('Identity', Class.new)
      end

      it 'normalizes keys to symbols' do
        expect(registry[:identity_repository]).to be(Identity)
      end
    end

    context 'with an unknown name' do
      it 'raises NotRegistered' do
        expect do
          registry[:payments_repository]
        end.to raise_error(described_class::NotRegistered, /payments_repository/)
      end
    end

    context 'with an entry that does not constantize' do
      let(:entries) { { identity_repository: 'MissingConstant' } }

      it 'raises InvalidEntry naming the entry' do
        expect do
          registry[:identity_repository]
        end.to raise_error(described_class::InvalidEntry, /identity_repository.*MissingConstant/)
      end
    end
  end

  describe '.suffix' do
    subject(:registry) { registry_class.new(entries) }

    let(:registry_class) do
      Class.new(described_class) do
        suffix :repository
      end
    end

    before do
      stub_const('Identity', Class.new)
    end

    it 'resolves bare names through the suffix' do
      expect(registry[:identity]).to be(Identity)
    end

    it 'still resolves exact names' do
      expect(registry[:identity_repository]).to be(Identity)
    end

    it 'is per-class' do
      expect(Class.new(registry_class).suffix_name).to be_nil
    end
  end

  describe '#registered?' do
    it 'answers true for a registered name' do
      expect(registry.registered?(:identity_repository)).to be(true)
    end

    it 'answers false for an unknown name' do
      expect(registry.registered?(:payments_repository)).to be(false)
    end
  end

  describe '#to_h' do
    it 'returns the raw entries' do
      expect(registry.to_h).to eq(identity_repository: 'Identity')
    end
  end

  describe '#names' do
    it 'lists the registered names' do
      expect(registry.names).to eq([:identity_repository])
    end
  end
end
