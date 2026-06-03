# frozen_string_literal: true

require 'layers_spec_helper'

RSpec.describe Layers::Result do
  describe '.success' do
    execute(:result) do
      described_class.success('value', { source: 'test' })
    end

    it 'returns a success result' do
      expect(result).to be_success
    end

    it 'is not a failure' do
      expect(result).not_to be_failure
    end

    it 'sets the value' do
      expect(result.value).to eq('value')
    end

    it 'sets the metadata' do
      expect(result.metadata).to eq({ source: 'test' })
    end

    it 'has no errors' do
      expect(result.errors).to be_empty
    end
  end

  describe '.failure' do
    execute(:result) do
      described_class.failure('went wrong', { source: 'test' })
    end

    it 'returns a failure result' do
      expect(result).to be_failure
    end

    it 'is not a success' do
      expect(result).not_to be_success
    end

    it 'normalizes a string error to an array' do
      expect(result.errors).to eq(['went wrong'])
    end

    it 'sets the metadata' do
      expect(result.metadata).to eq({ source: 'test' })
    end

    context 'with no errors given' do
      execute(:result) do
        described_class.failure
      end

      it 'has an empty errors array' do
        expect(result.errors).to eq([])
      end
    end

    context 'with an array of errors' do
      execute(:result) do
        described_class.failure(['first', 'second'])
      end

      it 'keeps the array' do
        expect(result.errors).to eq(['first', 'second'])
      end
    end

    context 'with an exception' do
      execute(:result) do
        described_class.failure(ArgumentError.new('boom'))
      end

      it 'normalizes the exception to its class and message' do
        expect(result.errors).to eq(['ArgumentError: boom'])
      end
    end

    context 'with an arbitrary object' do
      execute(:result) do
        described_class.failure(:boom)
      end

      it 'wraps the object in an array' do
        expect(result.errors).to eq([:boom])
      end
    end
  end

  describe '#and_then' do
    let(:probe) { spy('Probe') }

    context 'when the result is a failure' do
      subject(:result) { described_class.failure('boom') }

      execute(:chained) do
        result.and_then { |value| probe.call(value) }
      end

      it 'returns itself' do
        expect(chained).to be(result)
      end

      it 'does not call the block' do
        expect(probe).not_to have_received(:call)
      end
    end

    context 'when the block returns a result' do
      subject(:result) { described_class.success('value') }

      let(:next_result) { described_class.success('next') }

      execute(:chained) do
        result.and_then { |_value| next_result }
      end

      it 'returns the block result' do
        expect(chained).to be(next_result)
      end
    end

    context 'when the block returns a plain value' do
      subject(:result) { described_class.success('value', { source: 'test' }) }

      execute(:chained) do
        result.and_then(&:upcase)
      end

      it 'wraps the value in a success result' do
        expect(chained).to be_success
      end

      it 'sets the new value' do
        expect(chained.value).to eq('VALUE')
      end

      it 'carries the metadata forward' do
        expect(chained.metadata).to eq({ source: 'test' })
      end
    end

    context 'when the block raises' do
      subject(:result) { described_class.success('value', { source: 'test' }) }

      execute(:chained) do
        result.and_then { raise ArgumentError, 'boom' }
      end

      it 'returns a failure result' do
        expect(chained).to be_failure
      end

      it 'normalizes the exception into the errors' do
        expect(chained.errors).to eq(['ArgumentError: boom'])
      end

      it 'records the exception class in the metadata' do
        expect(chained.metadata).to eq({ source: 'test', exception: 'ArgumentError' })
      end
    end
  end

  describe '#on_success' do
    let(:probe) { spy('Probe') }

    context 'when the result is a success' do
      subject(:result) { described_class.success('value') }

      execute(:returned) do
        result.on_success { |value| probe.call(value) }
      end

      it 'returns itself for chaining' do
        expect(returned).to be(result)
      end

      it 'yields the value' do
        expect(probe).to have_received(:call).with('value')
      end
    end

    context 'when the result is a failure' do
      subject(:result) { described_class.failure('boom') }

      execute(:returned) do
        result.on_success { |value| probe.call(value) }
      end

      it 'returns itself for chaining' do
        expect(returned).to be(result)
      end

      it 'does not yield' do
        expect(probe).not_to have_received(:call)
      end
    end
  end

  describe '#on_failure' do
    let(:probe) { spy('Probe') }

    context 'when the result is a failure' do
      subject(:result) { described_class.failure('boom') }

      execute(:returned) do
        result.on_failure { |errors| probe.call(errors) }
      end

      it 'returns itself for chaining' do
        expect(returned).to be(result)
      end

      it 'yields the errors' do
        expect(probe).to have_received(:call).with(['boom'])
      end
    end

    context 'when the result is a success' do
      subject(:result) { described_class.success('value') }

      execute(:returned) do
        result.on_failure { |errors| probe.call(errors) }
      end

      it 'returns itself for chaining' do
        expect(returned).to be(result)
      end

      it 'does not yield' do
        expect(probe).not_to have_received(:call)
      end
    end
  end

  describe '#to_h' do
    context 'when the result is a success' do
      subject(:result) { described_class.success('value', { source: 'test' }) }

      it 'returns the success hash' do
        expect(result.to_h).to eq({ success: true, value: 'value', metadata: { source: 'test' } })
      end
    end

    context 'when the result is a failure' do
      subject(:result) { described_class.failure('boom') }

      it 'returns the failure hash' do
        expect(result.to_h).to eq({ success: false, errors: ['boom'], metadata: {} })
      end
    end
  end
end
