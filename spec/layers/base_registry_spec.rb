# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::BaseRegistry do
  subject(:registry) { described_class.new(identity: 'Identity') }

  describe '#[]' do
    context 'with a registered name' do
      let(:identity_class) { Class.new }

      before do
        stub_const('Identity', identity_class)
      end

      it 'constantizes the entry' do
        expect(registry[:identity]).to be(identity_class)
      end
    end

    context 'with a string name' do
      before do
        stub_const('Identity', Class.new)
      end

      it 'normalizes the name to a symbol' do
        expect(registry['identity']).to be(Identity)
      end
    end

    context 'with an entry registered before its constant exists' do
      subject(:registry) { described_class.new(late: 'LateArrival') }

      it 'resolves lazily at access time' do
        stub_const('LateArrival', Class.new)
        expect(registry[:late]).to be(LateArrival)
      end
    end

    context 'when the constant is replaced between accesses' do
      let(:replacement_class) { Class.new }

      before do
        stub_const('Identity', Class.new)
        registry[:identity]
        stub_const('Identity', replacement_class)
      end

      it 'resolves the current constant' do
        expect(registry[:identity]).to be(replacement_class)
      end
    end

    context 'with an unknown name' do
      it 'raises NotRegistered' do
        expect do
          registry[:payments]
        end.to raise_error(described_class::NotRegistered, /payments/)
      end
    end

    context 'with an entry that does not constantize' do
      subject(:registry) { described_class.new(identity: 'MissingConstant') }

      it 'raises InvalidEntry naming the entry' do
        expect do
          registry[:identity]
        end.to raise_error(described_class::InvalidEntry, /identity.*MissingConstant/)
      end
    end
  end

  describe '#register' do
    context 'with a single pair' do
      subject(:registry) { described_class.new }

      execute do
        registry.register(profile: 'Profile')
      end

      it 'registers the entry' do
        expect(registry.registered?(:profile)).to be(true)
      end
    end

    context 'with several pairs' do
      subject(:registry) { described_class.new }

      execute do
        registry.register(profile: 'Profile', user_account: 'UserAccount')
      end

      it 'registers every entry' do
        expect(registry.registered).to contain_exactly(:profile, :user_account)
      end
    end

    context 'with a class entry' do
      subject(:registry) { described_class.new }

      let(:identity_class) { Class.new }

      before do
        stub_const('Identity', identity_class)
      end

      execute do
        registry.register(identity: Identity)
      end

      it 'stores the class name' do
        expect(registry.to_h).to eq(identity: 'Identity')
      end

      it 'resolves back to the class' do
        expect(registry[:identity]).to be(identity_class)
      end
    end

    context 'with a string key' do
      subject(:registry) { described_class.new }

      execute do
        registry.register('identity' => 'Identity')
      end

      it 'normalizes the key to a symbol' do
        expect(registry.registered).to eq([:identity])
      end
    end

    context 'with an already-registered name' do
      execute do
        registry.register(identity: 'Replacement')
      end

      it 'replaces the entry' do
        expect(registry.to_h).to eq(identity: 'Replacement')
      end
    end
  end

  describe '#remove' do
    execute do
      registry.remove(:identity)
    end

    it 'forgets the registration' do
      expect(registry.registered?(:identity)).to be(false)
    end

    it 'removes the entry' do
      expect(registry.to_h).to eq({})
    end
  end

  describe '#registered' do
    it 'lists the registered names' do
      expect(registry.registered).to eq([:identity])
    end
  end

  describe '#registered?' do
    it 'answers true for a registered name' do
      expect(registry.registered?(:identity)).to be(true)
    end

    it 'answers false for an unknown name' do
      expect(registry.registered?(:payments)).to be(false)
    end
  end

  describe '#to_h' do
    it 'returns the entries' do
      expect(registry.to_h).to eq(identity: 'Identity')
    end

    context 'when the returned hash is mutated' do
      execute do
        registry.to_h[:identity] = 'Tampered'
      end

      it 'does not affect the registry' do
        expect(registry.to_h).to eq(identity: 'Identity')
      end
    end
  end

  describe '#defaults' do
    subject(:registry) { registry_class.new }

    let(:registry_class) do
      Class.new(described_class) do


        private

        def defaults
          { 'identity' => Identity }
        end
      end
    end

    before do
      stub_const('Identity', Class.new)
    end

    it 'seeds the store with coerced defaults' do
      expect(registry.to_h).to eq(identity: 'Identity')
    end
  end
end
